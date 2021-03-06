# collection.js
#
# data object representing an collection
#
# Copyright 2011-2012, E14N https://e14n.com/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
_ = require("underscore")
Step = require("step")
databank = require("databank")
DatabankObject = databank.DatabankObject
ActivityObject = require("./activityobject").ActivityObject
Stream = require("./stream").Stream
URLMaker = require("../urlmaker").URLMaker
AlreadyExistsError = databank.AlreadyExistsError
Collection = DatabankObject.subClass("collection", ActivityObject)
Collection.schema = ActivityObject.subSchema([
  "attachments"
  "inReplyTo"
], [
  "objectTypes"
  "members"
])
Collection.isList = (props, callback) ->
  User = require("./user").User
  if _(props).has("author") and _(props.author).isObject() and _(props.author).has("id") and _(props).has("objectTypes") and _(props).has("displayName") and _(props.objectTypes).isArray() and props.objectTypes.length is 1
    User.fromPerson props.author.id, (err, user) ->
      if err
        callback err, null
      else unless user
        callback null, false
      else
        callback null, user
      return

  else
    callback null, false
  return

Collection.checkList = (props, callback) ->
  user = undefined
  Step (->
    Collection.isList props, this
    return
  ), ((err, result) ->
    throw err  if err
    user = result
    unless user
      callback null, null
    else
      Collection.search
        "author.id": props.author.id
        displayName: props.displayName
      , this
    return
  ), (err, results) ->
    i = undefined
    diff = undefined
    hit = false
    return callback(err, null)  if err
    props.objectTypes.sort()
    i = 0
    while i < results.length
      continue  unless _(results[i]).has("objectTypes")
      results[i].objectTypes.sort()
      if props.objectTypes.join(",") is results[i].objectTypes.join(",") and (not _(props).has("id") or props.id isnt results[i].id)
        hit = true
        break
      i++
    if hit
      callback new AlreadyExistsError("A folder for '" + props.objectTypes.join(",") + "' named '" + props.displayName + "' already exists."), null
    else
      callback null, user

  return

Collection.beforeCreate = (props, callback) ->
  user = undefined
  Step (->
    Collection.checkList props, this
    return
  ), ((err, result) ->
    throw err  if err
    user = result
    ActivityObject.beforeCreate.apply Collection, [
      props
      this
    ]
    return
  ), (err, props) ->
    if err
      callback err, null
    else
      props.url = URLMaker.makeURL(user.nickname + "/list/" + props._uuid)  if user
      callback null, props
    return

  return

Collection::afterCreate = (callback) ->
  coll = this
  User = require("./user").User
  user = undefined
  Step (->
    ActivityObject::afterCreate.apply coll, [this]
    return
  ), ((err) ->
    throw err  if err
    Collection.isList coll, this
    return
  ), ((err, result) ->
    throw err  if err
    user = result
    unless user
      callback null
    else
      Stream.create
        name: coll.streamName()
      , this
    return
  ), ((err, stream) ->
    throw err  if err
    user.getLists coll.objectTypes[0], this
    return
  ), ((err, lists) ->
    throw err  if err
    lists.deliver coll.id, this
    return
  ), (err) ->
    if err
      callback err
    else
      callback null
    return

  return

Collection::beforeEfface = (callback) ->
  coll = this
  User = require("./user").User
  Step (->
    Collection.isList coll, this
    return
  ), ((err, isList) ->
    throw err  if err
    unless isList
      callback null
    else
      Stream.get coll.streamName(), this
    return
  ), ((err, stream) ->
    throw err  if err
    stream.del this
    return
  ), ((err) ->
    throw err  if err
    User.fromPerson coll.author.id, this
    return
  ), ((err, user) ->
    throw err  if err
    user.getLists coll.objectTypes[0], this
    return
  ), ((err, stream) ->
    throw err  if err
    stream.remove coll.id, this
    return
  ), (err) ->
    if err
      callback err
    else
      callback null
    return

  return

Collection::getStream = (callback) ->
  Stream.get @streamName(), callback
  return

Collection::expandFeeds = (callback) ->
  coll = this
  Step (->
    Collection.isList coll, this
    return
  ), ((err, isList) ->
    throw err  if err
    unless isList
      callback null
    else
      coll.getStream this
    return
  ), ((err, stream) ->
    throw err  if err
    stream.count @parallel()
    stream.getObjects 0, 4, @parallel()
    return
  ), (err, count, members) ->
    if err
      callback err
    else
      coll.members =
        totalItems: count
        url: URLMaker.makeURL("api/" + coll.objectType + "/" + coll._uuid + "/members")

      coll.members.items = members  if members and members.length > 0
      callback null
    return

  return

Collection::streamName = ->
  "collection:" + @id


# Represents the public; everyone, everywhere
Collection.PUBLIC = "http://activityschema.org/collection/public"
exports.Collection = Collection

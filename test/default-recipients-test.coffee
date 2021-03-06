# default-recipient-test.js
#
# Test setting default recipients for an activity
#
# Copyright 2012, E14N https://e14n.com/
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
assert = require("assert")
vows = require("vows")
Step = require("step")
_ = require("underscore")
OAuth = require("oauth-evanp").OAuth
httputil = require("./lib/http")
oauthutil = require("./lib/oauth")
setupApp = oauthutil.setupApp
register = oauthutil.register
newPair = oauthutil.newPair
newClient = oauthutil.newClient
ignore = (err) ->

suite = vows.describe("Default recipient API test")
makeCred = (cl, pair) ->
  consumer_key: cl.client_id
  consumer_secret: cl.client_secret
  token: pair.token
  token_secret: pair.token_secret

pairOf = (user) ->
  token: user.token
  token_secret: user.secret

clientCred = (cl) ->
  consumer_key: cl.client_id
  consumer_secret: cl.client_secret


# A batch for testing the visibility of bcc and bto addressing
suite.addBatch "When we set up the app":
  topic: ->
    setupApp @callback
    return

  teardown: (app) ->
    app.close()  if app and app.close
    return

  "it works": (err, app) ->
    assert.ifError err
    return

  "and we register a client":
    topic: ->
      newClient @callback
      return

    "it works": (err, cl) ->
      assert.ifError err
      assert.isObject cl
      return

    "and a user posts a new notice with no recipients":
      topic: (cl) ->
        cb = @callback
        Step (->
          newPair cl, "mrrogers", "be*my*neighbour", this
          return
        ), ((err, pair) ->
          act = undefined
          cred = undefined
          url = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "Hello, neighbour!"

          url = "http://localhost:4815/api/user/mrrogers/feed"
          httputil.postJSON url, cred, act, this
          return
        ), (err, act, resp) ->
          cb err, act
          return

        return

      "it works": (err, act) ->
        assert.ifError err
        return

      "it is cc to followers only": (err, act) ->
        assert.ifError err
        assert.isObject act
        assert.include act, "cc"
        assert.isArray act.cc
        assert.lengthOf act.cc, 1
        assert.isObject act.cc[0]
        assert.include act.cc[0], "objectType"
        assert.equal act.cc[0].objectType, "collection"
        assert.include act.cc[0], "id"
        assert.equal act.cc[0].id, "http://localhost:4815/api/user/mrrogers/followers"
        assert.isFalse act.hasOwnProperty("to")
        assert.isFalse act.hasOwnProperty("bto")
        assert.isFalse act.hasOwnProperty("bcc")
        return

    "and a user posts a comment in reply to a note with no recipients":
      topic: (cl) ->
        cb = @callback
        users =
          xtheowl: {}
          henrietta: {}

        Step (->
          register cl, "xtheowl", "b3nfr4nkl1n", @parallel()
          register cl, "henrietta", "meow|password|meow", @parallel()
          return
        ), ((err, user1, user2) ->
          act = undefined
          cred = undefined
          url = undefined
          throw err  if err
          users.xtheowl.profile = user1.profile
          users.henrietta.profile = user2.profile
          users.xtheowl.pair = pairOf(user1)
          users.henrietta.pair = pairOf(user2)
          cred = makeCred(cl, users.xtheowl.pair)
          act =
            verb: "post"
            to: [
              objectType: "person"
              id: users.henrietta.profile.id
            ]
            cc: [
              id: "http://localhost:4815/api/user/xtheowl/followers"
              objectType: "collection"
            ]
            object:
              objectType: "note"
              content: "Hello, neighbour."

          url = "http://localhost:4815/api/user/xtheowl/feed"
          httputil.postJSON url, cred, act, this
          return
        ), ((err, act, resp) ->
          reply = undefined
          cred = undefined
          url = undefined
          throw err  if err
          cred = makeCred(cl, users.henrietta.pair)
          reply =
            verb: "post"
            object:
              objectType: "comment"
              content: "Hello meow!"
              inReplyTo: act.object

          url = "http://localhost:4815/api/user/henrietta/feed"
          httputil.postJSON url, cred, reply, this
          return
        ), (err, act, resp) ->
          cb err, act, users
          return

        return

      "it works": (err, act, users) ->
        assert.ifError err
        return

      "it is to original poster and cc other recipients": (err, act, users) ->
        assert.ifError err
        assert.isObject act
        assert.include act, "to"
        assert.isArray act.to
        assert.lengthOf act.to, 1
        assert.isObject act.to[0]
        assert.include act.to[0], "objectType"
        assert.equal act.to[0].objectType, "person"
        assert.include act.to[0], "id"
        assert.equal users.xtheowl.profile.id, act.to[0].id
        assert.include act, "cc"
        assert.isArray act.cc
        assert.lengthOf act.cc, 1
        assert.isObject act.cc[0]
        assert.include act.cc[0], "objectType"
        assert.equal act.cc[0].objectType, "collection"
        assert.include act.cc[0], "id"
        assert.equal act.cc[0].id, "http://localhost:4815/api/user/xtheowl/followers"
        assert.isFalse act.hasOwnProperty("bto")
        assert.isFalse act.hasOwnProperty("bcc")
        return

    "and a user deletes an image with no recipients":
      topic: (cl) ->
        cb = @callback
        cred = undefined
        url = "http://localhost:4815/api/user/elaine/feed"
        Step (->
          newPair cl, "elaine", "bo0merang", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            to: [
              id: "http://localhost:4815/api/user/elaine/followers"
              objectType: "collection"
            ]
            object:
              objectType: "image"
              id: "http://photo.example/elaine/1"
              fullImage:
                url: "http://photo.example/elaine/1.jpg"

          httputil.postJSON url, cred, act, this
          return
        ), ((err, act, resp) ->
          del = undefined
          throw err  if err
          del =
            verb: "delete"
            object: act.object

          httputil.postJSON url, cred, del, this
          return
        ), (err, act, resp) ->
          cb err, act
          return

        return

      "it works": (err, act) ->
        assert.ifError err
        return

      "it is to followers": (err, act) ->
        assert.ifError err
        assert.isObject act
        assert.include act, "to"
        assert.isArray act.to
        assert.lengthOf act.to, 1
        assert.isObject act.to[0]
        assert.include act.to[0], "objectType"
        assert.equal act.to[0].objectType, "collection"
        assert.include act.to[0], "id"
        assert.equal act.to[0].id, "http://localhost:4815/api/user/elaine/followers"
        assert.isFalse act.hasOwnProperty("cc")
        assert.isFalse act.hasOwnProperty("bto")
        assert.isFalse act.hasOwnProperty("bcc")
        return

    "and a user updates an image with no recipients":
      topic: (cl) ->
        cb = @callback
        cred = undefined
        url = "http://localhost:4815/api/user/tuesday/feed"
        Step (->
          newPair cl, "tuesday", "i*have*feelings", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            to: [
              id: "http://localhost:4815/api/user/tuesday/followers"
              objectType: "collection"
            ]
            object:
              objectType: "image"
              id: "http://photo.example/tuesday/1"
              fullImage:
                url: "http://photo.example/tuesday/1.jpg"

          httputil.postJSON url, cred, act, this
          return
        ), ((err, act, resp) ->
          update = undefined
          obj = act.object
          throw err  if err
          obj.displayName = "Feelings"
          update =
            verb: "update"
            object: obj

          httputil.postJSON url, cred, update, this
          return
        ), (err, act, resp) ->
          cb err, act
          return

        return

      "it works": (err, act) ->
        assert.ifError err
        return

      "it is to followers": (err, act) ->
        assert.ifError err
        assert.isObject act
        assert.include act, "to"
        assert.isArray act.to
        assert.lengthOf act.to, 1
        assert.isObject act.to[0]
        assert.include act.to[0], "objectType"
        assert.equal act.to[0].objectType, "collection"
        assert.include act.to[0], "id"
        assert.equal act.to[0].id, "http://localhost:4815/api/user/tuesday/followers"
        assert.isFalse act.hasOwnProperty("cc")
        assert.isFalse act.hasOwnProperty("bto")
        assert.isFalse act.hasOwnProperty("bcc")
        return

suite["export"] module

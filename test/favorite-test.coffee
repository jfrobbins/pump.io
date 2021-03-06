# favorite-test.js
#
# Test the favorite module
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
databank = require("databank")
modelBatch = require("./lib/model").modelBatch
Databank = databank.Databank
DatabankObject = databank.DatabankObject
suite = vows.describe("favorite module interface")
testSchema =
  pkey: "id"
  fields: [
    "from"
    "to"
    "published"
    "updated"
  ]
  indices: [
    "from.id"
    "to.id"
  ]

testData =
  create:
    from:
      id: "http://example.org/people/evan"
      displayName: "Evan Prodromou"
      objectType: "person"

    to:
      id: "http://musicbrainz.org/release/fa20fff8-98c0-41a0-a60f-9c7cbafeb876"
      displayName: "Afterhours - The Velvet Underground"
      objectType: "audio"

  update:
    type: "hefty" # XXX: is there a real reason to update...?


# XXX: hack hack hack
# modelBatch hard-codes ActivityObject-style
mb = modelBatch("favorite", "Favorite", testSchema, testData)
mb["When we require the favorite module"]["and we get its Favorite class export"]["and we create a favorite instance"]["auto-generated fields are there"] = (err, created) ->
  assert.isString created.id
  assert.isString created.published
  assert.isString created.updated
  return

suite.addBatch mb
suite.addBatch "When we get the Favorite class":
  topic: ->
    require("../lib/model/favorite").Favorite

  "it exists": (Favorite) ->
    assert.isFunction Favorite
    return

  "it has an id() method": (Favorite) ->
    assert.isFunction Favorite.id
    return

  "and we get a new id":
    topic: (Favorite) ->
      from = "http://example.com/user/1"
      to = "http://example.net/image/35"
      Favorite.id from, to

    "it is a string": (id) ->
      assert.isString id
      return

suite["export"] module

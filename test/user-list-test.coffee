# user-list-test.js
#
# Test the user module's list methods
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
_ = require("underscore")
Step = require("step")
fs = require("fs")
path = require("path")
URLMaker = require("../lib/urlmaker").URLMaker
schema = require("../lib/schema").schema
Stream = require("../lib/model/stream").Stream
NotInStreamError = require("../lib/model/stream").NotInStreamError
Databank = databank.Databank
DatabankObject = databank.DatabankObject
suite = vows.describe("user module list interface")
tc = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json")))
suite.addBatch "When we get the User class":
  topic: ->
    cb = @callback
    
    # Need this to make IDs
    URLMaker.hostname = "example.net"
    
    # Dummy databank
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    db.connect {}, (err) ->
      User = undefined
      DatabankObject.bank = db
      User = require("../lib/model/user").User or null
      cb null, User
      return

    return

  "it exists": (User) ->
    assert.isFunction User
    return

  "and we create a user":
    topic: (User) ->
      props =
        nickname: "fred"
        password: "a cardigan"

      User.create props, @callback
      return

    teardown: (user) ->
      if user and user.del
        user.del (err) ->

      return

    "it works": (err, user) ->
      assert.ifError err
      return

    "it has a getLists() method": (err, user) ->
      assert.isFunction user.getLists
      return

    "and we get their list stream":
      topic: (user) ->
        user.getLists "person", @callback
        return

      "it works": (err, stream) ->
        assert.ifError err
        assert.isObject stream
        assert.instanceOf stream, Stream
        return

      "and we count the number of lists":
        topic: (stream, user) ->
          stream.count @callback
          return

        "it works": (err, count) ->
          assert.ifError err
          return

        "it is zero": (err, count) ->
          assert.equal count, 0
          return

      "and we get the latest lists":
        topic: (stream, user) ->
          stream.getIDs 0, 20, @callback
          return

        "it works": (err, ids) ->
          assert.ifError err
          return

        "it is an array with zero items": (err, ids) ->
          assert.isArray ids
          assert.lengthOf ids, 0
          return

suite["export"] module

# stream-test.js
#
# Test the stream module
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
Step = require("step")
fs = require("fs")
path = require("path")
URLMaker = require("../lib/urlmaker").URLMaker
schema = require("../lib/schema").schema
Databank = databank.Databank
DatabankObject = databank.DatabankObject
suite = vows.describe("stream objects interface")
tc = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json")))

# Test the object methods
suite.addBatch "When we get the Stream class":
  topic: ->
    cb = @callback
    
    # Need this to make IDs
    URLMaker.hostname = "example.net"
    
    # Dummy databank
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    db.connect {}, (err) ->
      Stream = undefined
      mod = undefined
      if err
        cb err, null
        return
      DatabankObject.bank = db
      mod = require("../lib/model/stream")
      unless mod
        cb new Error("No module"), null
        return
      Stream = mod.Stream
      unless Stream
        cb new Error("No class"), null
        return
      cb null, Stream
      return

    return

  "it works": (err, Stream) ->
    assert.ifError err
    assert.isFunction Stream
    return

  "and we create a stream object":
    topic: (Stream) ->
      Stream.create
        name: "object-test-1"
      , @callback
      return

    "it has a getObjects() method": (err, stream) ->
      assert.ifError err
      assert.isFunction stream.getObjects
      return

    "it has a getObjectsGreaterThan() method": (err, stream) ->
      assert.ifError err
      assert.isFunction stream.getObjectsGreaterThan
      return

    "it has a getObjectsLessThan() method": (err, stream) ->
      assert.ifError err
      assert.isFunction stream.getObjectsLessThan
      return

    "it has a deliverObject() method": (err, stream) ->
      assert.ifError err
      assert.isFunction stream.deliverObject
      return

    "it has a removeObject() method": (err, stream) ->
      assert.ifError err
      assert.isFunction stream.removeObject
      return

    "and we get some objects":
      topic: (stream) ->
        stream.getObjects 0, 20, @callback
        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "it is an empty array": (err, objects) ->
        assert.isArray objects
        assert.lengthOf objects, 0
        return

    "and we get objects with indexes greater than some object":
      topic: (stream) ->
        cb = @callback
        NotInStreamError = require("../lib/model/stream").NotInStreamError
        stream.getObjectsGreaterThan
          a: "b"
        , 10, (err, objects) ->
          if err and err instanceof NotInStreamError
            cb null
          else if err
            cb err
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err) ->
        assert.ifError err
        return

    "and we get objects with indexes less than some object":
      topic: (stream) ->
        cb = @callback
        NotInStreamError = require("../lib/model/stream").NotInStreamError
        stream.getObjectsLessThan
          a: "b"
        , 10, (err, objects) ->
          if err and err instanceof NotInStreamError
            cb null
          else if err
            cb err
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err) ->
        assert.ifError err
        return

    "and we remove an object that doesn't exist":
      topic: (stream) ->
        cb = @callback
        NotInStreamError = require("../lib/model/stream").NotInStreamError
        stream.removeObject
          a: "b"
        , (err) ->
          if err and err instanceof NotInStreamError
            cb null
          else if err
            cb err
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err) ->
        assert.ifError err
        return

  "and we create another stream":
    topic: (Stream) ->
      Stream.create
        name: "object-test-2"
      , @callback
      return

    "it works": (err, stream) ->
      assert.ifError err
      assert.isObject stream
      return

    "and we deliver an object to it":
      topic: (stream) ->
        cb = @callback
        obj =
          objectType: "person"
          id: "acct:evan@status.net"

        stream.deliverObject obj, cb
        return

      "it works": (err) ->
        assert.ifError err
        return

      "and we get the stream's objects":
        topic: (stream) ->
          stream.getObjects 0, 20, @callback
          return

        "it works": (err, objects) ->
          assert.ifError err
          return

        "results look right": (err, objects) ->
          assert.ifError err
          assert.isArray objects
          assert.lengthOf objects, 1
          assert.isObject objects[0]
          assert.include objects[0], "objectType"
          assert.equal objects[0].objectType, "person"
          assert.include objects[0], "id"
          assert.equal objects[0].id, "acct:evan@status.net"
          return

  "and we create a stream and deliver many objects to it":
    topic: (Stream) ->
      cb = @callback
      stream = undefined
      Step (->
        Stream.create
          name: "object-test-3"
        , this
        return
      ), ((err, results) ->
        i = undefined
        group = @group()
        throw err  if err
        stream = results
        i = 0
        while i < 50
          stream.deliverObject
            id: "http://example.com/person" + i
            objectType: "person"
          , group()
          i++
        return
      ), (err) ->
        if err
          cb err, null
        else
          cb null, stream
        return

      return

    "it works": (err, stream) ->
      assert.ifError err
      assert.isObject stream
      return

    "and we get the stream's objects":
      topic: (stream) ->
        stream.getObjects 0, 100, @callback
        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "results look right": (err, objects) ->
        i = undefined
        obj = undefined
        seen = {}
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 50
        i = 0
        while i < objects.length
          obj = objects[i]
          assert.isObject obj
          assert.include obj, "objectType"
          assert.equal obj.objectType, "person"
          assert.include obj, "id"
          assert.match obj.id, /http:\/\/example.com\/person[0-9]+/
          assert.isUndefined seen[obj.id]
          seen[obj.id] = obj
          i++
        return

      "and we get objects less than some object":
        topic: (objects, stream) ->
          cb = @callback
          stream.getObjectsLessThan objects[30], 20, (err, results) ->
            cb err, results, objects
            return

          return

        "it works": (err, objects, total) ->
          assert.ifError err
          return

        "results look right": (err, objects, total) ->
          i = undefined
          obj = undefined
          assert.ifError err
          assert.isArray objects
          assert.lengthOf objects, 20
          i = 0
          while i < objects.length
            obj = objects[i]
            assert.isObject obj
            assert.include obj, "objectType"
            assert.equal obj.objectType, "person"
            assert.include obj, "id"
            assert.match obj.id, /http:\/\/example.com\/person[0-9]+/
            assert.deepEqual objects[i], total[i + 10]
            i++
          return

      "and we get objects greater than some object":
        topic: (objects, stream) ->
          cb = @callback
          stream.getObjectsGreaterThan objects[9], 20, (err, results) ->
            cb err, results, objects
            return

          return

        "it works": (err, objects, total) ->
          assert.ifError err
          return

        "results look right": (err, objects, total) ->
          i = undefined
          obj = undefined
          assert.ifError err
          assert.isArray objects
          assert.lengthOf objects, 20
          i = 0
          while i < objects.length
            obj = objects[i]
            assert.isObject obj
            assert.include obj, "objectType"
            assert.equal obj.objectType, "person"
            assert.include obj, "id"
            assert.match obj.id, /http:\/\/example.com\/person[0-9]+/
            assert.deepEqual objects[i], total[i + 10]
            i++
          return

  "and we create a stream and deliver an object then remove it":
    topic: (Stream) ->
      cb = @callback
      stream = undefined
      Step (->
        Stream.create
          name: "object-test-4"
        , this
        return
      ), ((err, results) ->
        i = undefined
        group = @group()
        throw err  if err
        stream = results
        i = 0
        while i < 50
          stream.deliverObject
            id: "http://example.com/person" + i
            objectType: "person"
          , group()
          i++
        return
      ), ((err) ->
        throw err  if err
        stream.removeObject
          id: "http://example.com/person23"
          objectType: "person"
        , this
        return
      ), (err) ->
        if err
          cb err, null
        else
          cb null, stream
        return

      return

    "it works": (err, stream) ->
      assert.ifError err
      assert.isObject stream
      return

    "and we get its objects":
      topic: (stream) ->
        stream.getObjects 0, 100, @callback
        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "results look right": (err, objects) ->
        i = undefined
        obj = undefined
        seen = {}
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 49
        i = 0
        while i < objects.length
          obj = objects[i]
          assert.isObject obj
          assert.include obj, "objectType"
          assert.equal obj.objectType, "person"
          assert.include obj, "id"
          assert.notEqual obj.id, "http://example.com/person23"
          assert.match obj.id, /http:\/\/example.com\/person[0-9]+/
          assert.isUndefined seen[obj.id]
          seen[obj.id] = obj
          i++
        return

suite["export"] module

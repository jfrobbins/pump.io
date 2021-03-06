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
_ = require("underscore")
assert = require("assert")
vows = require("vows")
databank = require("databank")
Step = require("step")
fs = require("fs")
path = require("path")
URLMaker = require("../lib/urlmaker").URLMaker
modelBatch = require("./lib/model").modelBatch
schema = require("../lib/schema").schema
Databank = databank.Databank
DatabankObject = databank.DatabankObject
tc = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json")))
suite = vows.describe("stream interface")

# XXX: check other types
testSchema = pkey: "name"
testData =
  create:
    name: "evan-inbox"

  update:
    something: "value" # Not clear what we update here


# XXX: hack hack hack
# modelBatch hard-codes ActivityObject-style
mb = modelBatch("stream", "Stream", testSchema, testData)

# This class has a weird schema format
mb["When we require the stream module"]["and we get its Stream class export"]["and we get its schema"]["topic"] = (Stream) ->
  Stream.schema.stream or null

mb["When we require the stream module"]["and we get its Stream class export"]["and we create a stream instance"]["auto-generated fields are there"] = (err, created) ->
  
  # No auto-gen fields, so...
  assert.isTrue true
  return

mb["When we require the stream module"]["and we get its Stream class export"]["and we create a stream instance"]["and we modify it"]["it is modified"] = (err, updated) ->
  assert.ifError err
  return

suite.addBatch mb
act1 = null
suite.addBatch "When we create a new stream":
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
      Stream.create
        name: "test"
      , cb
      return

    return

  "it works": (err, stream) ->
    assert.ifError err
    assert.isObject stream
    return

  "it has a deliver() method": (err, stream) ->
    assert.isFunction stream.deliver
    return

  "it has a remove() method": (err, stream) ->
    assert.isFunction stream.remove
    return

  "it has a getIDs() method": (err, stream) ->
    assert.isFunction stream.getIDs
    return

  "it has a getIDsGreaterThan() method": (err, stream) ->
    assert.isFunction stream.getIDsGreaterThan
    return

  "it has a getIDsLessThan() method": (err, stream) ->
    assert.isFunction stream.getIDsLessThan
    return

  "it has a count() method": (err, stream) ->
    assert.isFunction stream.count
    return

  "and we create a single activity":
    topic: (stream) ->
      Activity = require("../lib/model/activity").Activity
      props =
        actor:
          id: "urn:uuid:8f64087d-fffc-4fe0-9848-c18ae611cafd"
          displayName: "Delbert Fnorgledap"
          objectType: "person"

        verb: "post"
        object:
          objectType: "note"
          content: "Feeling groovy."

      Activity.create props, @callback
      return

    "it works": (err, activity) ->
      assert.ifError err
      assert.isObject activity
      return

    "and we deliver it to the stream":
      topic: (activity, stream) ->
        act1 = activity
        stream.deliver activity.id, @callback
        return

      "it works": (err) ->
        assert.ifError err
        return

      "and we get the stream's activities":
        topic: (activity, stream) ->
          stream.getIDs 0, 100, @callback
          return

        "it works": (err, activities) ->
          assert.ifError err
          assert.isArray activities
          assert.isTrue activities.length > 0
          return

        "our activity is in there": (err, activities) ->
          assert.isTrue activities.some((item) ->
            item is act1.id
          )
          return

      "and we count the stream's activities":
        topic: (activity, stream) ->
          stream.count @callback
          return

        "it works": (err, cnt) ->
          assert.ifError err
          return

        "it has the right value (1)": (err, cnt) ->
          assert.equal cnt, 1
          return

      "and we count the stream's activities with Stream.count()":
        topic: (activity, stream) ->
          Stream = require("../lib/model/stream").Stream
          Stream.count stream.name, @callback
          return

        "it works": (err, cnt) ->
          assert.ifError err
          return

        "it has the right value (1)": (err, cnt) ->
          assert.equal cnt, 1
          return

suite.addBatch "When we setup the env":
  topic: ->
    cb = @callback
    
    # Need this to make IDs
    URLMaker.hostname = "example.net"
    
    # Dummy databank
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    stream = null
    db.connect {}, (err) ->
      if err
        cb err, null
        return
      DatabankObject.bank = db
      Stream = require("../lib/model/stream").Stream
      cb null, Stream
      return

    return

  "it works": (err, Stream) ->
    assert.ifError err
    return

  "and we create a stream":
    topic: (Stream) ->
      Stream.create
        name: "test-remove-1"
      , @callback
      return

    "it works": (err, stream) ->
      assert.ifError err
      assert.isObject stream
      return

    "and we add 5000 ids":
      topic: (stream, Stream) ->
        cb = @callback
        Step (->
          i = undefined
          group = @group()
          i = 0
          while i < 5000
            stream.deliver "tag:pump.io,2012:stream-test:object:" + i, group()
            i++
          return
        ), (err) ->
          if err
            cb err
          else
            cb null
          return

        return

      "it works": (err) ->
        assert.ifError err
        return

      "and we remove one":
        topic: (stream, Stream) ->
          stream.remove "tag:pump.io,2012:stream-test:object:2500", @callback
          return

        "it works": (err) ->
          assert.ifError err
          return

        "and we get all the IDs":
          topic: (stream, Stream) ->
            stream.getIDs 0, 5000, @callback
            return

          "it works": (err, ids) ->
            assert.ifError err
            assert.isArray ids
            return

          "it is the right size": (err, ids) ->
            assert.equal ids.length, 4999 # 5000 - 1
            return

          "removed ID is missing": (err, ids) ->
            assert.equal ids.indexOf("tag:pump.io,2012:stream-test:object:2500"), -1
            return

        "and we get the count":
          topic: (stream, Stream) ->
            stream.count @callback
            return

          "it works": (err, count) ->
            assert.ifError err
            assert.isNumber count
            return

          "it is the right size": (err, count) ->
            assert.equal count, 4999 # 5000 - 1
            return

  "and we try to remove() from an empty stream":
    topic: (Stream) ->
      cb = @callback
      Stream.create
        name: "test-remove-2"
      , (err, stream) ->
        if err
          cb err
        else
          stream.remove "tag:pump.io,2012:stream-test:object:6000", (err) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we remove a not-present object from a non-empty stream":
    topic: (Stream) ->
      cb = @callback
      stream = undefined
      Step (->
        Stream.create
          name: "test-remove-3"
        , this
        return
      ), ((err, results) ->
        i = undefined
        group = @group()
        throw err  if err
        stream = results
        i = 0
        while i < 5000
          stream.deliver "tag:pump.io,2012:stream-test:object:" + i, group()
          i++
        return
      ), (err) ->
        if err
          cb err
        else
          
          # 6666 > 5000
          stream.remove "tag:pump.io,2012:stream-test:object:6666", (err) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

suite.addBatch "When we deliver a lot of activities to a stream":
  topic: ->
    cb = @callback
    Activity = require("../lib/model/activity").Activity
    actor =
      id: "urn:uuid:c484d84e-6afa-4c51-ac9a-f8738d48569c"
      displayName: "Counter"
      objectType: "service"

    
    # Need this to make IDs
    URLMaker.hostname = "example.net"
    
    # Dummy databank
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    stream = null
    Step (->
      db.connect {}, this
      return
    ), ((err) ->
      throw err  if err
      DatabankObject.bank = db
      Stream = require("../lib/model/stream").Stream
      Stream.create
        name: "scale-test"
      , this
      return
    ), ((err, results) ->
      i = undefined
      act = undefined
      group = @group()
      throw err  if err
      stream = results
      addNew = (act, callback) ->
        Activity.create act, (err, results) ->
          if err
            callback err, null
          else
            stream.deliver results.id, (err) ->
              if err
                callback err, null
              else
                callback err, results
              return

          return

        return

      i = 0
      while i < 10000
        act =
          actor: actor
          verb: "post"
          object:
            objectType: "note"
            content: "Note #" + i

        addNew act, group()
        i++
      return
    ), (err, activities) ->
      if err
        cb err, null
      else
        cb err, stream
      return

    return

  "it works": (err, stream) ->
    assert.ifError err
    assert.isObject stream
    return

  "and we count the number of elements":
    topic: (stream) ->
      stream.count @callback
      return

    "it works": (err, cnt) ->
      assert.ifError err
      return

    "it gives the right value (10000)": (err, cnt) ->
      assert.equal cnt, 10000
      return

  "and we get all the activities in little chunks":
    topic: (stream) ->
      cb = @callback
      Step (->
        i = undefined
        group = @group()
        i = 0
        while i < 500
          stream.getIDs i * 20, (i + 1) * 20, group()
          i++
        return
      ), (err, chunks) ->
        if err
          cb err, null
        else
          cb null, chunks
        return

      return

    "it works": (err, chunks) ->
      assert.ifError err
      return

    "results have right size": (err, chunks) ->
      i = undefined
      assert.lengthOf chunks, 500
      i = 0
      while i < 500
        assert.lengthOf chunks[i], 20
        i++
      return

    "there are no duplicates": (err, chunks) ->
      i = undefined
      j = undefined
      seen = {}
      i = 0
      while i < chunks.length
        j = 0
        while j < chunks[i].length
          assert.isUndefined seen[chunks[i][j]]
          seen[chunks[i][j]] = true
          j++
        i++
      return

  "and we get all the activities in big chunks":
    topic: (stream) ->
      cb = @callback
      Step (->
        i = undefined
        group = @group()
        i = 0
        while i < 20
          stream.getIDs i * 500, (i + 1) * 500, group()
          i++
        return
      ), (err, chunks) ->
        if err
          cb err, null
        else
          cb null, chunks
        return

      return

    "it works": (err, chunks) ->
      assert.ifError err
      return

    "results have right size": (err, chunks) ->
      i = undefined
      assert.lengthOf chunks, 20
      i = 0
      while i < 20
        assert.lengthOf chunks[i], 500
        i++
      return

    "there are no duplicates": (err, chunks) ->
      i = undefined
      j = undefined
      seen = {}
      i = 0
      while i < chunks.length
        j = 0
        while j < chunks[i].length
          assert.isUndefined seen[chunks[i][j]]
          seen[chunks[i][j]] = true
          j++
        i++
      return

  "and we get all the activities one at a time":
    topic: (stream) ->
      cb = @callback
      Step (->
        i = undefined
        group = @group()
        i = 0
        while i < 10000
          stream.getIDs i, i + 1, group()
          i++
        return
      ), (err, chunks) ->
        if err
          cb err, null
        else
          cb null, chunks
        return

      return

    "it works": (err, chunks) ->
      assert.ifError err
      return

    "results have right size": (err, chunks) ->
      i = undefined
      assert.lengthOf chunks, 10000
      i = 0
      while i < 10000
        assert.lengthOf chunks[i], 1
        i++
      return

    "there are no duplicates": (err, chunks) ->
      i = undefined
      j = undefined
      seen = {}
      i = 0
      while i < chunks.length
        j = 0
        while j < chunks[i].length
          assert.isUndefined seen[chunks[i][j]]
          seen[chunks[i][j]] = true
          j++
        i++
      return

  "and we get all the activities at once":
    topic: (stream) ->
      cb = @callback
      stream.getIDs 0, 10000, cb
      return

    "it works": (err, chunk) ->
      assert.ifError err
      return

    "results have right size": (err, chunk) ->
      assert.lengthOf chunk, 10000
      return

    "there are no duplicates": (err, chunk) ->
      i = undefined
      seen = {}
      i = 0
      while i < chunk.length
        assert.isUndefined seen[chunk[i]]
        seen[chunk[i]] = true
        i++
      return

    "and we get IDs greater than some ID":
      topic: (all, stream) ->
        cb = @callback
        target = all[4216]
        stream.getIDsGreaterThan target, 20, (err, results) ->
          cb err, results, all
          return

        return

      "it works": (err, ids, all) ->
        assert.ifError err
        assert.isArray ids
        assert.isArray all
        return

      "it is the right size": (err, ids, all) ->
        assert.lengthOf ids, 20
        return

      "it has the right values": (err, ids, all) ->
        assert.deepEqual ids, all.slice(4217, 4237)
        return

    "and we get IDs less than some ID":
      topic: (all, stream) ->
        cb = @callback
        target = all[8423]
        stream.getIDsLessThan target, 20, (err, results) ->
          cb err, results, all
          return

        return

      "it works": (err, ids, all) ->
        assert.ifError err
        assert.isArray ids
        assert.isArray all
        return

      "it is the right size": (err, ids, all) ->
        assert.lengthOf ids, 20
        return

      "it has the right values": (err, ids, all) ->
        assert.deepEqual ids, all.slice(8403, 8423)
        return

    "and we get the indices of items in the stream":
      topic: (all, stream) ->
        cb = @callback
        Step (->
          i = undefined
          group = @group()
          i = 0
          while i < all.length
            stream.indexOf all[i], group()
            i++
          return
        ), cb
        return

      "it works": (err, indices) ->
        assert.ifError err
        return

      "they have the right values": (err, indices) ->
        i = undefined
        assert.ifError err
        assert.isArray indices
        assert.lengthOf indices, 10000
        i = 0
        while i < indices.length
          assert.equal indices[i], i
          i++
        return

    "and we get too many IDs greater than some ID at the end":
      topic: (all, stream) ->
        cb = @callback
        target = all[9979]
        stream.getIDsGreaterThan target, 40, (err, results) ->
          cb err, results, all
          return

        return

      "it works": (err, ids, all) ->
        assert.ifError err
        assert.isArray ids
        assert.isArray all
        return

      "it is the right size": (err, ids, all) ->
        assert.lengthOf ids, 20
        return

      "it has the right values": (err, ids, all) ->
        assert.deepEqual ids, all.slice(9980, 10000)
        return

    "and we too many get IDs less than some ID toward the beginning":
      topic: (all, stream) ->
        cb = @callback
        target = all[40]
        stream.getIDsLessThan target, 60, (err, results) ->
          cb err, results, all
          return

        return

      "it works": (err, ids, all) ->
        assert.ifError err
        assert.isArray ids
        assert.isArray all
        return

      "it is the right size": (err, ids, all) ->
        assert.lengthOf ids, 40
        return

      "it has the right values": (err, ids, all) ->
        assert.deepEqual ids, all.slice(0, 40)
        return

    "and we get a negative number of IDs less than an ID":
      topic: (all, stream) ->
        cb = @callback
        stream.getIDsLessThan all[100], -50, (err, ids) ->
          if err
            cb null
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err) ->
        assert.ifError err
        return

    "and we get zero IDs less than an ID":
      topic: (all, stream) ->
        cb = @callback
        stream.getIDsLessThan all[100], 0, cb
        return

      "it works": (err, ids) ->
        assert.ifError err
        assert.isArray ids
        return

      "it returns the right value": (err, ids) ->
        assert.lengthOf ids, 0
        return

    "and we get a negative number of IDs greater than an ID":
      topic: (all, stream) ->
        cb = @callback
        stream.getIDsGreaterThan all[100], -50, (err, ids) ->
          if err
            cb null
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err) ->
        assert.ifError err
        return

    "and we get zero IDs greater than an ID":
      topic: (all, stream) ->
        cb = @callback
        stream.getIDsGreaterThan all[100], 0, cb
        return

      "it works": (err, ids) ->
        assert.ifError err
        assert.isArray ids
        return

      "it returns the right value": (err, ids) ->
        assert.lengthOf ids, 0
        return

  "and we try to get activities starting at a negative number":
    topic: (stream) ->
      cb = @callback
      stream.getIDs -10, 20, (err, activities) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we try to get activities ending at a negative number":
    topic: (stream) ->
      cb = @callback
      stream.getIDs 10, -20, (err, activities) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we try to get activities with start after the end":
    topic: (stream) ->
      cb = @callback
      stream.getIDs 110, 100, (err, activities) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we try to get activities start and end equal":
    topic: (stream) ->
      cb = @callback
      stream.getIDs 50, 50, cb
      return

    "it works": (err, results) ->
      assert.ifError err
      return

    "results are empty": (err, results) ->
      assert.isEmpty results
      return

  "and we get IDs greater than an ID not in the stream":
    topic: (stream) ->
      cb = @callback
      stream.getIDsGreaterThan "tag:pump.io,2012:nonexistent", 20, (err, ids) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we get IDs less than an ID not in the stream":
    topic: (stream) ->
      cb = @callback
      stream.getIDsLessThan "tag:pump.io,2012:nonexistent", 20, (err, ids) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we get zero IDs greater than an ID not in the stream":
    topic: (stream) ->
      cb = @callback
      stream.getIDsGreaterThan "tag:pump.io,2012:nonexistent", 0, (err, ids) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

  "and we get zero IDs less than an ID not in the stream":
    topic: (stream) ->
      cb = @callback
      stream.getIDsLessThan "tag:pump.io,2012:nonexistent", 0, (err, ids) ->
        if err
          cb null
        else
          cb new Error("Unexpected success!")
        return

      return

    "it fails correctly": (err) ->
      assert.ifError err
      return

suite["export"] module

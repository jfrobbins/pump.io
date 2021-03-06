# dispatch-test.js
#
# Test for dispatch module
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
cluster = require("cluster")
suite = vows.describe("dispatch module interface")
suite.addBatch "When we require the dispatch module":
  topic: ->
    require "../lib/dispatch"

  "it returns an object": (Dispatch) ->
    assert.isObject Dispatch
    return

  "and we check its methods":
    topic: (Dispatch) ->
      Dispatch

    "it has a start method": (Dispatch) ->
      assert.isFunction Dispatch.start
      return

    "and we start the dispatcher":
      topic: (Dispatch) ->
        callback = @callback
        Dispatch.start()
        callback null, "parent"
        return

      "it works": (err, name) ->
        assert.ifError err
        assert.isTrue name is "parent" or name is "child"
        return

suite["export"] module

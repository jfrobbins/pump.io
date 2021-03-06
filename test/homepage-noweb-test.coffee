# homepage-noweb-test.js
#
# Test that the home page shows API documentation when noweb is enabled
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
oauthutil = require("./lib/oauth")
Browser = require("zombie")
setupAppConfig = oauthutil.setupAppConfig
suite = vows.describe("homepage with noweb test")

# A batch to test that the API docs are served at root
suite.addBatch "When we set up the app":
  topic: ->
    setupAppConfig
      noweb: 1
    , @callback
    return

  teardown: (app) ->
    app.close()  if app and app.close
    return

  "it works": (err, app) ->
    assert.ifError err
    return

  "and we visit the root URL":
    topic: ->
      browser = undefined
      browser = new Browser()
      browser.visit "http://localhost:4815/", @callback
      return

    "it works": (err, br) ->
      assert.ifError err
      assert.isTrue br.success
      return

    "it has the right title": (err, br) ->
      assert.ifError err
      assert.isTrue br.success
      assert.equal br.text("title"), "API - pump.io"
      return

    "it has the right H1": (err, br) ->
      assert.ifError err
      assert.isTrue br.success
      assert.equal br.text("H1"), "pump.io API"
      return

suite["export"] module

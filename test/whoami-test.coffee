# whoami-test.js
#
# Test checking who you are
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
httputil = require("./lib/http")
oauthutil = require("./lib/oauth")
actutil = require("./lib/activity")
setupApp = oauthutil.setupApp
newCredentials = oauthutil.newCredentials
newPair = oauthutil.newPair
newClient = oauthutil.newClient
register = oauthutil.register
ignore = (err) ->

makeCred = (cl, pair) ->
  consumer_key: cl.client_id
  consumer_secret: cl.client_secret
  token: pair.token
  token_secret: pair.token_secret

suite = vows.describe("whoami api test")

# A batch to test following/unfollowing users
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

  "and we check the whoami endpoint": httputil.endpoint("/api/whoami", ["GET"])
  "and we get a new client":
    topic: ->
      newClient @callback
      return

    "it works": (err, cl) ->
      assert.ifError err
      assert.isObject cl
      return

    "and we get a new pair":
      topic: (cl) ->
        newPair cl, "crab", "pincers*69", @callback
        return

      "it works": (err, cred) ->
        assert.ifError err
        assert.isObject cred
        return

      "and we get the /api/whoami endpoint":
        topic: (pair, cl) ->
          cred = makeCred(cl, pair)
          httputil.getJSON "http://localhost:4815/api/whoami", cred, @callback
          return

        "it works": (err, doc, response) ->
          assert.ifError err
          return

        "and we examine the document":
          topic: (doc) ->
            doc

          "it has the right ID": (doc) ->
            assert.equal doc.id, "http://localhost:4815/api/user/crab/profile"
            return

suite["export"] module

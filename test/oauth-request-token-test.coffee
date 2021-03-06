# oauth-request-token-test.js
#
# Test the OAuth request token interface
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
querystring = require("querystring")
http = require("http")
OAuth = require("oauth-evanp").OAuth
httputil = require("./lib/http")
oauthutil = require("./lib/oauth")
accessToken = oauthutil.accessToken
requestToken = oauthutil.requestToken
register = oauthutil.register
setupApp = oauthutil.setupApp
newClient = oauthutil.newClient
newCredentials = oauthutil.newCredentials
suite = vows.describe("user API")
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

  "and we request a token with no Authorization":
    topic: ->
      cb = @callback
      httputil.post "localhost", 4815, "/oauth/request_token", {}, (err, res, body) ->
        if err
          cb err
        else if res.statusCode is 400
          cb null
        else
          cb new Error("Unexpected success")
        return

      return

    "it fails correctly": (err, cred) ->
      assert.ifError err
      return

  "and we request a token with an invalid client_id":
    topic: ->
      cb = @callback
      badcl =
        client_id: "NOTACLIENTID"
        client_secret: "NOTTHERIGHTSECRET"

      requestToken badcl, (err, rt) ->
        if err
          cb null
        else
          cb new Error("Unexpected success")
        return

      return

    "it fails correctly": (err, cred) ->
      assert.ifError err
      return

  "and we create a client using the api":
    topic: ->
      newClient @callback
      return

    "it works": (err, cl) ->
      assert.ifError err
      assert.isObject cl
      assert.isString cl.client_id
      assert.isString cl.client_secret
      return

    "and we request a token with a valid client_id and invalid client_secret":
      topic: (cl) ->
        cb = @callback
        badcl =
          client_id: cl.client_id
          client_secret: "NOTTHERIGHTSECRET"

        requestToken badcl, (err, rt) ->
          if err
            cb null
          else
            cb new Error("Unexpected success")
          return

        return

      "it fails correctly": (err, cred) ->
        assert.ifError err
        return

    "and we request a request token with valid client_id and client_secret":
      topic: (cl) ->
        requestToken cl, @callback
        return

      "it works": (err, cred) ->
        assert.ifError err
        assert.isObject cred
        return

      "it has the right results": (err, cred) ->
        assert.include cred, "token"
        assert.isString cred.token
        assert.include cred, "token_secret"
        assert.isString cred.token_secret
        return


# A batch to test parallel requests
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

  "and we create a client using the api":
    topic: ->
      newClient @callback
      return

    "it works": (err, cl) ->
      assert.ifError err
      return

    "and we get two request tokens in series":
      topic: (cl) ->
        cb = @callback
        Step (->
          requestToken cl, this
          return
        ), ((err, rt1) ->
          throw err  if err
          requestToken cl, this
          return
        ), (err, rt2) ->
          cb err
          return

        return

      "it works": (err) ->
        assert.ifError err
        return


# A batch to test parallel requests
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

  "and we create a client using the api":
    topic: ->
      newClient @callback
      return

    "it works": (err, cl) ->
      assert.ifError err
      return

    "and we get many request tokens in parallel":
      topic: (cl) ->
        cb = @callback
        Step (->
          i = undefined
          group = @group()
          i = 0
          while i < 20
            requestToken cl, group()
            i++
          return
        ), (err, rts) ->
          cb err
          return

        return

      "it works": (err) ->
        assert.ifError err
        return


# A batch to test request token after access token
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

  "and we get a request token after getting an access token":
    topic: ->
      cb = @callback
      cl = undefined
      Step (->
        newClient this
        return
      ), ((err, res) ->
        throw err  if err
        cl = res
        register cl, "mary", "l1ttl3*l4mb", this
        return
      ), ((err, user) ->
        throw err  if err
        accessToken cl,
          nickname: "mary"
          password: "l1ttl3*l4mb"
        , this
        return
      ), ((err, pair) ->
        throw err  if err
        requestToken cl, this
        return
      ), (err, rt) ->
        if err
          cb err, null
        else
          cb null, rt
        return

      return

    "it works": (err, rt) ->
      assert.ifError err
      assert.isObject rt
      return

suite["export"] module

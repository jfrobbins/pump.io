# provider-test.js
#
# Test the provider module
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
_ = require("underscore")
fs = require("fs")
path = require("path")
schema = require("../lib/schema")
URLMaker = require("../lib/urlmaker").URLMaker
randomString = require("../lib/randomstring").randomString
Client = require("../lib/model/client").Client
RequestToken = require("../lib/model/requesttoken").RequestToken
AccessToken = require("../lib/model/accesstoken").AccessToken
User = require("../lib/model/user").User
methodContext = require("./lib/methods").methodContext
Databank = databank.Databank
DatabankObject = databank.DatabankObject
tc = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json")))
testClient = null
ignore = (err) ->


# Need this to make IDs

# Dummy databank
# Correct
# this is correct
# this is correct
# this is correct
# this is correct
# this is correct
# correct
# correct
# correct
# correct
# correct
# correct
# correct
# correct
# should succeed here
# correct
# should fail
# should succeed here
# correct
# should succeed here

# Double-dip!
vows.describe("provider module interface").addBatch("When we get the provider module":
  topic: ->
    cb = @callback
    URLMaker.hostname = "example.net"
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    db.connect {}, (err) ->
      mod = undefined
      DatabankObject.bank = db
      Client.create
        title: "Test App"
        description: "App for testing"
      , (err, client) ->
        if err
          cb err, null
        else
          testClient = client
          mod = require("../lib/provider")
          cb null, mod
        return

      return

    return

  "there is one": (err, mod) ->
    assert.isObject mod
    return

  "and we get its Provider export":
    topic: (mod) ->
      mod.Provider

    "it exists": (Provider) ->
      assert.isFunction Provider
      return

    "and we create a new Provider":
      topic: (Provider) ->
        new Provider()

      "it exists": (provider) ->
        assert.isObject provider
        return

      "and we check its methods": methodContext([
        "previousRequestToken"
        "tokenByConsumer"
        "applicationByConsumerKey"
        "fetchAuthorizationInformation"
        "validToken"
        "tokenByTokenAndVerifier"
        "validateNotReplayClient"
        "userIdByToken"
        "authenticateUser"
        "associateTokenToUser"
        "generateRequestToken"
        "generateAccessToken"
        "cleanRequestTokens"
      ])
      "and we use previousRequestToken() on a previously unseen token":
        topic: (provider) ->
          provider.previousRequestToken "ZZZZZZZZZZZZZZZZZZZZZ", @callback
          return

        "it returns correct value": (err, token) ->
          assert.ifError err
          assert.isString token
          assert.equal token, "ZZZZZZZZZZZZZZZZZZZZZ"
          return

      "and we use previousRequestToken() on an existing but unused token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/12345/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err, null
            else
              provider.previousRequestToken rt.token, (err, token) ->
                if err
                  cb err, rt
                else
                  cb null, rt
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          assert.isObject rt
          return

        teardown: (requestToken) ->
          requestToken.del ignore  if requestToken and requestToken.del
          return

      "and we use previousRequestToken() on a used token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "charlie"
              password: "h4X0r*4*u"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), (err, results) ->
            if err
              cb err, null
              return
            at = results
            provider.previousRequestToken rt.token, (err, newt) ->
              if err
                cb null,
                  user: user
                  rt: rt
                  at: at

              else
                cb new Error("Unexpected success"), null
              return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we use tokenByConsumer() on an unknown consumer key":
        topic: (provider) ->
          cb = @callback
          provider.tokenByConsumer "BOGUSCONSUMERKEY", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Got unexpected tokens")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we use tokenByConsumer() on a consumer key with no request tokens":
        topic: (provider) ->
          cb = @callback
          Client.create
            title: "No requests client"
          , (err, client) ->
            if err
              cb err, null
              return
            provider.tokenByConsumer client.consumer_key, (err, rt) ->
              if err
                cb null,
                  client: client

              else
                cb new Error("Unexpected success"), null
              return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.client.del ignore  if results and results.client and results.client.del
          return

      "and we use tokenByConsumer() on a consumer key with a single request token":
        topic: (provider) ->
          cb = @callback
          Client.create
            title: "Single request client"
          , (err, client) ->
            if err
              cb err, null
              return
            props =
              consumer_key: client.consumer_key
              callback: "http://example.com/madeup/endpoint"

            RequestToken.create props, (err, rt) ->
              if err
                cb err, null
                return
              provider.tokenByConsumer client.consumer_key, (err, token) ->
                if err
                  cb err, null
                else
                  cb null,
                    client: client
                    requestToken: rt
                    token: token

                return

              return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        "results are correct": (err, results) ->
          assert.isObject results.token
          assert.equal results.token.token, results.requestToken.token
          return

        teardown: (results) ->
          results.client.del ignore  if results and results.client and results.client.del
          results.requestToken.del ignore  if results and results.requestToken and results.requestToken.del
          return

      "and we use applicationByConsumerKey() on an invalid key":
        topic: (provider) ->
          cb = @callback
          provider.applicationByConsumerKey "BOGUSCONSUMERKEY", (err, result) ->
            if err
              cb null
            else
              cb new Error("Got unexpected results")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we use applicationByConsumerKey() on a valid key":
        topic: (provider) ->
          provider.applicationByConsumerKey testClient.consumer_key, @callback
          return

        "it works": (err, client) ->
          assert.ifError err
          assert.isObject client
          assert.instanceOf client, Client
          return

        "it has the right fields": (err, client) ->
          assert.isString client.consumer_key
          assert.isString client.secret
          return

      "and we use fetchAuthorizationInformation() with a nonexistent username and existent token":
        topic: (provider) ->
          cb = @callback
          username = "nonexistent"
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/madeup/endpoint"

          RequestToken.create props, (err, rt) ->
            if err
              cb err, null
            else
              provider.fetchAuthorizationInformation username, rt.token, (err, app, user) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected authorization information"), null
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          assert.isObject rt
          assert.instanceOf rt, RequestToken
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we use fetchAuthorizationInformation() with a existent username and unassociated token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "david"
            password: "log-me-in"
          , (err, user) ->
            if err
              cb err, null
            else
              props =
                consumer_key: testClient.consumer_key
                callback: "http://example.com/madeup/endpoint"

              RequestToken.create props, (err, rt) ->
                if err
                  cb err, null
                else
                  provider.fetchAuthorizationInformation "david", rt.token, (err, app, found) ->
                    if err
                      cb null,
                        user: user
                        rt: rt

                    else
                      cb new Error("Unexpected authorization information"), null
                    return

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          assert.isObject results
          assert.isObject results.rt
          assert.isObject results.user
          assert.instanceOf results.rt, RequestToken
          assert.instanceOf results.user, User
          return

        teardown: (results) ->
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.user.del ignore  if results and results.user and results.user.del
          return

      "and we use fetchAuthorizationInformation() with a existent username and non-existent token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "ernie"
            password: "let*me*in"
          , (err, user) ->
            if err
              cb err, null
            else
              provider.fetchAuthorizationInformation "ernie", "bogusrequesttoken", (err, app, found) ->
                if err
                  cb null, user
                else
                  cb new Error("Unexpected authorization information"), null
                return

            return

          return

        "it fails correctly": (err, user) ->
          assert.ifError err
          assert.isObject user
          assert.instanceOf user, User
          return

        teardown: (user) ->
          user.del ignore  if user and user.del
          return

      "and we use fetchAuthorizationInformation() with a existent username and associated token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "francine"
            password: "!monkey!"
          , (err, user) ->
            if err
              cb err, null
            else
              props =
                consumer_key: testClient.consumer_key
                callback: "http://example.com/madeup/endpoint"

              RequestToken.create props, (err, rt) ->
                if err
                  cb err, null
                else
                  provider.associateTokenToUser "francine", rt.token, (err, res) ->
                    if err
                      cb err, null
                    else
                      provider.fetchAuthorizationInformation "francine", rt.token, (err, app, found) ->
                        if err
                          cb err, null
                        else
                          cb null,
                            user: user
                            rt: rt
                            app: app
                            found: found

                        return

                    return

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          assert.isObject results
          assert.isObject results.rt
          assert.isObject results.user
          assert.isObject results.app
          assert.isObject results.found
          assert.instanceOf results.rt, RequestToken
          assert.instanceOf results.user, User
          assert.instanceOf results.app, Client
          assert.instanceOf results.found, RequestToken
          assert.equal results.rt.token, results.found.token
          assert.equal results.rt.token_secret, results.found.token_secret
          return

        "results have right properties": (err, results) ->
          assert.isString results.app.title
          assert.isString results.app.description
          assert.isString results.found.token
          assert.isString results.found.username
          return

        teardown: (results) ->
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.user.del ignore  if results and results.user and results.user.del
          return

      "and we use fetchAuthorizationInformation() with a client without a title":
        topic: (provider) ->
          cb = @callback
          user = undefined
          rt = undefined
          client = undefined
          Step (->
            Client.create {}, this
            return
          ), ((err, cl) ->
            throw err  if err
            client = cl
            User.create
              nickname: "franklin"
              password: "mint condition"
            , this
            return
          ), ((err, u) ->
            throw err  if err
            user = u
            props =
              consumer_key: testClient.consumer_key
              callback: "http://example.com/madeup/endpoint"

            RequestToken.create props, this
            return
          ), ((err, requesttoken) ->
            throw err  if err
            rt = requesttoken
            provider.associateTokenToUser "franklin", rt.token, this
            return
          ), ((err, res) ->
            throw err  if err
            provider.fetchAuthorizationInformation "franklin", rt.token, this
            return
          ), (err, app, found) ->
            if err
              cb err, null
            else
              cb null,
                user: user
                rt: rt
                app: app
                found: found

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          assert.isObject results
          assert.isObject results.rt
          assert.isObject results.user
          assert.isObject results.app
          assert.isObject results.found
          assert.instanceOf results.rt, RequestToken
          assert.instanceOf results.user, User
          assert.instanceOf results.app, Client
          assert.instanceOf results.found, RequestToken
          assert.equal results.rt.token, results.found.token
          assert.equal results.rt.token_secret, results.found.token_secret
          return

        "results have right properties": (err, results) ->
          assert.isString results.app.title
          assert.isString results.app.description
          assert.isString results.found.token
          assert.isString results.found.username
          return

        teardown: (results) ->
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.user.del ignore  if results and results.user and results.user.del
          results.app.del ignore  if results and results.app and results.app.del
          return

      "and we call validToken() with an invalid token":
        topic: (provider) ->
          cb = @callback
          provider.validToken "NOT A VALID TOKEN", (err, token) ->
            if err
              cb null
            else
              cb new Error("Unexpected result")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call validToken() with a request token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err, null
            else
              provider.validToken rt.token, (err, token) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected result"), null
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call validToken() with a valid access token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "gerald"
              password: "one23four56"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            provider.validToken at.access_token, this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              cb null,
                user: user
                rt: rt
                at: at

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call tokenByTokenAndVerifier() with bad token and bad verifier":
        topic: (provider) ->
          cb = @callback
          provider.tokenByTokenAndVerifier "NOT A TOKEN", "NOT A VERIFIER", (err, token) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call tokenByTokenAndVerifier() with bad token and good verifier":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err
            else
              provider.tokenByTokenAndVerifier "NOT A TOKEN", rt.verifier, (err, newt) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call tokenByTokenAndVerifier() with good token and bad verifier":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err
            else
              provider.tokenByTokenAndVerifier rt.token, "NOT A VERIFIER", (err, newt) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call tokenByTokenAndVerifier() with good token and wrong verifier":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt1) ->
            if err
              cb err
            else
              RequestToken.create props, (err, rt2) ->
                if err
                  cb err
                else
                  provider.tokenByTokenAndVerifier rt1.token, rt2.verifier, (err, newt) ->
                    if err
                      cb null,
                        rt1: rt1
                        rt2: rt2

                    else
                      cb new Error("Unexpected success"), null
                    return

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.rt1.del ignore  if results and results.rt1 and results.rt1.del
          results.rt2.del ignore  if results and results.rt2 and results.rt2.del
          return

      "and we call tokenByTokenAndVerifier() with good token and good verifier":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err
            else
              provider.tokenByTokenAndVerifier rt.token, rt.verifier, (err, newt) ->
                if err
                  cb err, null
                else
                  cb null,
                    rt: rt
                    newt: newt

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          assert.isObject results.newt
          assert.instanceOf results.newt, RequestToken
          assert.equal results.rt.token, results.newt.token
          assert.equal results.rt.verifier, results.newt.verifier
          return

        teardown: (results) ->
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call validateNotReplayClient() with an invalid consumer key and invalid access token":
        topic: (provider) ->
          cb = @callback
          ts = Number(Date.now() / 1000).toString(10)
          randomString 8, (err, nonce) ->
            provider.validateNotReplayClient "NOT A CONSUMER KEY", "NOT AN ACCESS TOKEN", ts, nonce, (err, isNotReplay) ->
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

      "and we call validateNotReplayClient() with an invalid consumer key and valid access token and a good timestamp and an unused nonce":
        topic: (provider) ->
          cb = @callback
          ts = Number((Date.now() / 1000)).toString(10)
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "isadora"
              password: "dunkin*donuts"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            randomString 8, this
            return
          ), (err, nonce) ->
            if err
              cb err, null
            else
              provider.validateNotReplayClient "NOTACONSUMERKEY", at.access_token, ts, nonce, (err, isNotReplay) ->
                if err
                  cb null,
                    at: at
                    rt: rt
                    user: user

                else
                  cb new Error("Unexpected success")
                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call validateNotReplayClient() with a valid consumer key and invalid access token":
        topic: (provider) ->
          cb = @callback
          ts = Number(Date.now() / 1000).toString(10)
          randomString 8, (err, nonce) ->
            provider.validateNotReplayClient testClient.consumer_key, "NOT AN ACCESS TOKEN", ts, nonce, (err, isNotReplay) ->
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

      "and we call validateNotReplayClient() with a valid consumer key and access token and a long-expired timestamp":
        topic: (provider) ->
          cb = @callback
          ts = Number((Date.now() / 1000) - (24 * 60 * 60 * 365)).toString(10)
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "harvey"
              password: "wall-banger"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            randomString 8, this
            return
          ), (err, nonce) ->
            if err
              cb err, null
            else
              provider.validateNotReplayClient testClient.consumer_key, at.access_token, ts, nonce, (err, isNotReplay) ->
                if err
                  cb err, null
                else if isNotReplay
                  cb new Error("Unexpected success"), null
                else
                  cb null,
                    at: at
                    rt: rt
                    user: user

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call validateNotReplayClient() with a valid access token and a far-future timestamp":
        topic: (provider) ->
          cb = @callback
          ts = Number((Date.now() / 1000) + (24 * 60 * 60 * 365)).toString(10)
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "ignace"
              password: "krazy*katt"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            randomString 8, this
            return
          ), (err, nonce) ->
            if err
              cb err, null
            else
              provider.validateNotReplayClient testClient.consumer_key, at.access_token, ts, nonce, (err, isNotReplay) ->
                if err
                  cb err, null
                else if isNotReplay
                  cb new Error("Unexpected success"), null
                else
                  cb null,
                    at: at
                    rt: rt
                    user: user

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call validateNotReplayClient() with a valid access token and a good timestamp and a used nonce":
        topic: (provider) ->
          cb = @callback
          ts = Number((Date.now() / 1000)).toString(10)
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          nonce = undefined
          Step (->
            User.create
              nickname: "jerry"
              password: "sein*feld"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            randomString 8, this
            return
          ), ((err, results) ->
            throw err  if err
            nonce = results
            provider.validateNotReplayClient testClient.consumer_key, at.access_token, ts, nonce, this
            return
          ), (err, isNotReplay) ->
            if err
              cb err, null
            else unless isNotReplay
              cb new Error("Unexpected failure on first validation"), null
            else
              provider.validateNotReplayClient testClient.consumer_key, at.access_token, ts, nonce, (err, isNotReplay) ->
                if err
                  cb err, null
                else if isNotReplay
                  cb new Error("Unexpected success"), null
                else
                  cb null,
                    at: at
                    rt: rt
                    user: user

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call validateNotReplayClient() with a valid access token and a good timestamp and an unused nonce":
        topic: (provider) ->
          cb = @callback
          ts = Number((Date.now() / 1000)).toString(10)
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "karen"
              password: "findl4y."
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            at = results
            randomString 8, this
            return
          ), (err, nonce) ->
            if err
              cb err, null
            else
              provider.validateNotReplayClient testClient.consumer_key, at.access_token, ts, nonce, (err, isNotReplay) ->
                if err
                  cb err, null
                else unless isNotReplay
                  cb new Error("Unexpected failure"), null
                else
                  cb null,
                    at: at
                    rt: rt
                    user: user

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call userIdByToken() with an invalid access token":
        topic: (provider) ->
          cb = @callback
          provider.userIdByToken "NOT AN ACCESS TOKEN", (err, userId) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call userIdByToken() with a valid request token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          Step (->
            User.create
              nickname: "larry"
              password: "leisure*suit"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), (err, results) ->
            if err
              cb err
            else
              provider.userIdByToken rt.token, (err, userId) ->
                if err
                  cb null,
                    user: user
                    rt: rt

                else
                  cb new Error("Unexpected success")
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call userIdByToken() with a valid access token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          at = undefined
          Step (->
            User.create
              nickname: "mary"
              password: "quite,contrary"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            user = results
            RequestToken.create props, this
            return
          ), ((err, results) ->
            throw err  if err
            rt = results
            provider.associateTokenToUser user.nickname, rt.token, this
            return
          ), ((err, results) ->
            throw err  if err
            provider.generateAccessToken rt.token, this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              at = results
              provider.userIdByToken at.access_token, (err, userId) ->
                if err
                  cb err, null
                else
                  cb null,
                    user: user
                    rt: rt
                    at: at
                    id: userId

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        "it has the right properties": (err, results) ->
          assert.isString results.id.id
          assert.equal results.user.nickname, results.id.id
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call authenticateUser with a non-existent username":
        topic: (provider) ->
          cb = @callback
          provider.authenticateUser "nonexistentuser", "badpassword", "badtoken", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call authenticateUser with a good username and non-matching password":
        topic: (provider) ->
          cb = @callback
          user = undefined
          Step (->
            User.create
              nickname: "nancy"
              password: "change-me"
            , this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              user = results
              provider.authenticateUser "nancy", "badpass", "badtoken", (err, rt) ->
                if err
                  cb null, user
                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, user) ->
          assert.ifError err
          return

        teardown: (user) ->
          user.del ignore  if user and user.del
          return

      "and we call authenticateUser with a good username and good password and non-existent token":
        topic: (provider) ->
          cb = @callback
          user = undefined
          Step (->
            User.create
              nickname: "oliver"
              password: "followThe$"
            , this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              user = results
              provider.authenticateUser "oliver", "followThe$", "badtoken", (err, rt) ->
                if err
                  cb null, user
                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, user) ->
          assert.ifError err
          return

        teardown: (user) ->
          user.del ignore  if user and user.del
          return

      "and we call authenticateUser with a good username and good password and already-assigned token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user1 = undefined
          user2 = undefined
          rt = undefined
          Step (->
            User.create
              nickname: "paul"
              password: "austrian,"
            , @parallel()
            User.create
              nickname: "pauline"
              password: "freezy*trees"
            , @parallel()
            RequestToken.create props, @parallel()
            return
          ), ((err, res1, res2, res3) ->
            throw err  if err
            user1 = res1
            user2 = res2
            rt = res3
            provider.associateTokenToUser user2.nickname, rt.token, this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              provider.authenticateUser user1.nickname, "austrian", rt.token, (err, newt) ->
                if err
                  cb null,
                    user1: user1
                    user2: user2
                    rt: rt

                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user1.del ignore  if results and results.user1 and results.user1.del
          results.user2.del ignore  if results and results.user2 and results.user2.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call authenticateUser with a good username and good password and an unused request token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          Step (->
            User.create
              nickname: "quincy"
              password: "john*adams"
            , @parallel()
            RequestToken.create props, @parallel()
            return
          ), (err, res1, res2) ->
            if err
              cb err, null
            else
              user = res1
              rt = res2
              provider.authenticateUser user.nickname, "john*adams", rt.token, (err, newt) ->
                if err
                  cb err, null
                else
                  cb null,
                    user: user
                    rt: rt
                    newt: newt

                return

            return

          return

        "it works correctly": (err, results) ->
          assert.ifError err
          assert.equal results.newt.token, results.rt.token
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call associateTokenToUser with an invalid username and an invalid token":
        topic: (provider) ->
          cb = @callback
          provider.associateTokenToUser "nonexistentuser", "badtoken", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call associateTokenToUser with a valid username and an invalid token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "ronald"
            password: "mcdonald1"
          , (err, user) ->
            if err
              cb err, null
            else
              provider.associateTokenToUser user.nickname, "badtoken", (err, newt) ->
                if err
                  cb null, user
                else
                  cb new Error("Unexpected success")
                return

            return

          return

        "it works correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (user) ->
          user.del ignore  if user and user.del
          return

      "and we call associateTokenToUser with a invalid username and a valid token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          RequestToken.create props, (err, rt) ->
            if err
              cb err, null
            else
              provider.associateTokenToUser "nonexistentuser", rt.token, (err, newt) ->
                if err
                  cb null, rt
                else
                  cb err, null
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call associateTokenToUser with a valid username and a used token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user1 = undefined
          user2 = undefined
          rt = undefined
          Step (->
            User.create
              nickname: "samuel"
              password: "dinos4ur"
            , @parallel()
            User.create
              nickname: "samantha"
              password: "a w0mbat"
            , @parallel()
            RequestToken.create props, @parallel()
            return
          ), ((err, res1, res2, res3) ->
            throw err  if err
            user1 = res1
            user2 = res2
            rt = res3
            provider.associateTokenToUser user2.nickname, rt.token, this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              provider.associateTokenToUser user1.nickname, rt.token, (err, newt) ->
                if err
                  cb null,
                    user1: user1
                    user2: user2
                    rt: rt

                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user1.del ignore  if results and results.user1 and results.user1.del
          results.user2.del ignore  if results and results.user2 and results.user2.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call associateTokenToUser with a valid username and an unused token":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          user = undefined
          rt = undefined
          Step (->
            User.create
              nickname: "thomas"
              password: "aquinas1"
            , @parallel()
            RequestToken.create props, @parallel()
            return
          ), (err, res1, res2) ->
            if err
              cb err, null
            else
              user = res1
              rt = res2
              provider.associateTokenToUser user.nickname, rt.token, (err, newt) ->
                if err
                  cb err, null
                else
                  cb null,
                    user: user
                    rt: rt
                    newt: newt

                return

            return

          return

        "it works correctly": (err, results) ->
          assert.ifError err
          assert.equal results.newt.token, results.rt.token
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          return

      "and we call generateRequestToken with an invalid consumer key":
        topic: (provider) ->
          cb = @callback
          provider.generateRequestToken "NOT A KEY", "http://example.com/callback", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call generateRequestToken with a valid consumer key and an invalid callback url":
        topic: (provider) ->
          cb = @callback
          provider.generateRequestToken testClient.consumer_key, "NOT A VALID URL", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call generateRequestToken with a valid consumer key and a valid callback url":
        topic: (provider) ->
          cb = @callback
          provider.generateRequestToken testClient.consumer_key, "http://example.com/callback", (err, rt) ->
            if err
              cb err, null
            else
              cb null, rt
            return

          return

        "it works": (err, rt) ->
          assert.ifError err
          assert.isObject rt
          assert.instanceOf rt, RequestToken
          return

        "it has the right attributes": (err, rt) ->
          assert.isString rt.token
          assert.isString rt.token_secret
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call generateAccessToken() with an invalid request token":
        topic: (provider) ->
          cb = @callback
          provider.generateAccessToken "NOT A TOKEN", (err, at) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we call generateAccessToken() with an unassociated request token":
        topic: (provider) ->
          cb = @callback
          provider.generateRequestToken testClient.consumer_key, "http://example.com/callback", (err, rt) ->
            if err
              cb err, null
            else
              provider.generateAccessToken rt.token, (err, at) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected success")
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we call generateAccessToken() with an already-used request token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "ulysses"
            password: "s. grant"
          , (err, user) ->
            if err
              cb err, null
            else
              provider.generateRequestToken testClient.consumer_key, "http://example.com/callback", (err, rt) ->
                if err
                  cb err, null
                else
                  provider.associateTokenToUser "ulysses", rt.token, (err, newt) ->
                    if err
                      cb err, null
                    else
                      provider.generateAccessToken rt.token, (err, at) ->
                        if err
                          cb err, null
                        else
                          provider.generateAccessToken rt.token, (err, at) ->
                            if err
                              cb null,
                                rt: rt
                                user: user
                                at: at

                            else
                              cb new Error("Unexpected success")
                            return

                        return

                    return

                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we call generateAccessToken() with an associated request token":
        topic: (provider) ->
          cb = @callback
          User.create
            nickname: "valentine"
            password: "'s day 2012"
          , (err, user) ->
            if err
              cb err, null
            else
              provider.generateRequestToken testClient.consumer_key, "http://example.com/callback", (err, rt) ->
                if err
                  cb err, null
                else
                  provider.associateTokenToUser "valentine", rt.token, (err, newt) ->
                    if err
                      cb err, null
                    else
                      provider.generateAccessToken rt.token, (err, at) ->
                        if err
                          cb err, null
                        else
                          cb null,
                            rt: rt
                            user: user
                            at: at

                        return

                    return

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          assert.isObject results.at
          assert.instanceOf results.at, AccessToken
          return

        "it has the right properties": (err, results) ->
          assert.isString results.at.access_token
          assert.isString results.at.token_secret
          return

        teardown: (results) ->
          results.user.del ignore  if results and results.user and results.user.del
          results.rt.del ignore  if results and results.rt and results.rt.del
          results.at.del ignore  if results and results.at and results.at.del
          return

      "and we use tokenByTokenAndConsumer() on an invalid token and invalid consumer key":
        topic: (provider) ->
          cb = @callback
          provider.tokenByTokenAndConsumer "BADTOKEN", "BADCONSUMER", (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we use tokenByTokenAndConsumer() on an invalid token and valid consumer key":
        topic: (provider) ->
          cb = @callback
          provider.tokenByTokenAndConsumer "BADTOKEN", testClient.consumer_key, (err, rt) ->
            if err
              cb null
            else
              cb new Error("Unexpected success")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we use tokenByTokenAndConsumer() on a valid token and invalid consumer key":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          Step (->
            RequestToken.create props, this
            return
          ), (err, rt) ->
            if err
              cb err, null
            else
              provider.tokenByTokenAndConsumer rt.token, "BADCONSUMER", (err, newt) ->
                if err
                  cb null, rt
                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, rt) ->
          assert.ifError err
          return

        teardown: (rt) ->
          rt.del ignore  if rt and rt.del
          return

      "and we use tokenByTokenAndConsumer() on a valid token and mismatched consumer key":
        topic: (provider) ->
          cb = @callback
          props =
            consumer_key: testClient.consumer_key
            callback: "http://example.com/callback/abc123/"

          Step (->
            RequestToken.create props, @parallel()
            Client.create
              title: "Another App"
              description: "Whatever"
            , @parallel()
            return
          ), (err, rt, client) ->
            if err
              cb err, null
            else
              provider.tokenByTokenAndConsumer rt.token, client.consumer_key, (err, newt) ->
                if err
                  cb null,
                    rt: rt
                    client: client

                else
                  cb new Error("Unexpected success"), null
                return

            return

          return

        "it fails correctly": (err, results) ->
          assert.ifError err
          return

        teardown: (results) ->
          results.rt.del ignore  if results.rt and results.rt.del
          results.client.del ignore  if results.client and results.client.del
          return

      "and we use tokenByTokenAndConsumer() on a valid token and matching consumer key":
        topic: (provider) ->
          cb = @callback
          rt = undefined
          client = undefined
          Step (->
            Client.create
              title: "Successful App"
              description: "Whatever"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            client = results
            props =
              consumer_key: client.consumer_key
              callback: "http://example.com/callback/abc123/"

            RequestToken.create props, this
            return
          ), (err, results) ->
            if err
              cb err, null
            else
              rt = results
              provider.tokenByTokenAndConsumer rt.token, client.consumer_key, (err, newt) ->
                if err
                  cb err, null
                else
                  cb null,
                    rt: rt
                    client: client
                    newt: newt

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        "it returns the correct token": (err, results) ->
          assert.equal results.client.consumer_key, results.newt.consumer_key
          assert.equal results.rt.token, results.newt.token
          return

        teardown: (results) ->
          results.rt.del ignore  if results.rt and results.rt.del
          results.client.del ignore  if results.client and results.client.del
          return

      "and we use tokenByTokenAndConsumer() on a valid token and matching consumer key with multiple tokens":
        topic: (provider) ->
          cb = @callback
          rt1 = undefined
          rt2 = undefined
          client = undefined
          Step (->
            Client.create
              title: "Popular App"
              description: "Whatever"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            client = results
            props =
              consumer_key: client.consumer_key
              callback: "http://example.com/callback/abc123/"

            RequestToken.create props, @parallel()
            RequestToken.create props, @parallel()
            return
          ), (err, res1, res2) ->
            if err
              cb err, null
            else
              rt1 = res1
              rt2 = res2
              provider.tokenByTokenAndConsumer rt1.token, client.consumer_key, (err, newt) ->
                if err
                  cb err, null
                else
                  cb null,
                    rt1: rt1
                    rt2: rt2
                    client: client
                    newt: newt

                return

            return

          return

        "it works": (err, results) ->
          assert.ifError err
          return

        "it returns the correct token": (err, results) ->
          assert.equal results.client.consumer_key, results.newt.consumer_key
          assert.equal results.rt1.token, results.newt.token
          return

        teardown: (results) ->
          results.rt1.del ignore  if results.rt1 and results.rt1.del
          results.rt2.del ignore  if results.rt2 and results.rt2.del
          results.client.del ignore  if results.client and results.client.del
          return

      "and we use cleanRequestTokens() on an invalid consumer key":
        topic: (provider) ->
          cb = @callback
          provider.cleanRequestTokens "NOTACONSUMERKEY", (err) ->
            if err
              cb null
            else
              cb new Error("Unexpected success!")
            return

          return

        "it fails correctly": (err) ->
          assert.ifError err
          return

      "and we use cleanRequestTokens() on a consumer key with no request tokens":
        topic: (provider) ->
          cb = @callback
          client = undefined
          Step (->
            Client.create
              title: "No requests app"
            , this
            return
          ), ((err, results) ->
            throw err  if err
            client = results
            provider.cleanRequestTokens client.consumer_key, this
            return
          ), (err) ->
            if err
              cb err, null
            else
              cb null, client
            return

          return

        "it works": (err, client) ->
          assert.ifError err
          assert.isObject client
          return

        teardown: (client) ->
          client.del ignore  if client and client.del
          return

      "and we use cleanRequestTokens() on a consumer key with no out-of-date tokens":
        topic: (provider) ->
          cb = @callback
          client = undefined
          before = undefined
          after = undefined
          Step (->
            Client.create
              title: "No out of date requests app"
            , this
            return
          ), ((err, results) ->
            i = undefined
            group = @group()
            throw err  if err
            client = results
            i = 0
            while i < 5
              provider.generateRequestToken client.consumer_key, "http://localhost/callback", group()
              i++
            return
          ), ((err, rts) ->
            throw err  if err
            before = rts
            provider.cleanRequestTokens client.consumer_key, this
            return
          ), ((err) ->
            throw err  if err
            RequestToken.search
              consumer_key: client.consumer_key
            , this
            return
          ), (err, rts) ->
            if err
              cb err, null
            else
              after = rts
              cb null,
                client: client
                before: before
                after: after

            return

          return

        "it works": (err, res) ->
          assert.ifError err
          assert.isObject res
          assert.include res, "client"
          assert.include res, "before"
          assert.include res, "after"
          return

        "nothing was deleted": (err, res) ->
          b = res.before
          a = res.after
          i = undefined
          matchT = (tok) ->
            (rt) ->
              rt.token is tok

          i = 0
          while i < b.length
            assert.isTrue a.some(matchT(b[i].token))
            i++
          return

        teardown: (res) ->
          i = undefined
          res.client.del ignore  if res.client and res.client.del
          if res.before and res.before.length
            i = 0
            while i < res.before.length
              res.before[i].del ignore
              i++
          return

      "and we use cleanRequestTokens() on a consumer key with mixed out-of-date tokens":
        topic: (provider) ->
          cb = @callback
          client = undefined
          before = undefined
          outdated = undefined
          after = undefined
          Step (->
            Client.create
              title: "Some out-of-date requests app"
            , this
            return
          ), ((err, results) ->
            i = undefined
            group = @group()
            throw err  if err
            client = results
            i = 0
            while i < 10
              provider.generateRequestToken client.consumer_key, "http://localhost/callback", group()
              i++
            return
          ), ((err, rts) ->
            i = undefined
            touched = Date(Date.now() - 10 * 24 * 3600)
            bank = RequestToken.bank()
            group = @group()
            throw err  if err
            before = rts
            outdated = {}
            i = 0
            while i < 5
              outdated[before[i].token] = true
              bank.update "requesttoken", before[i].token,
                updated: touched
              , group()
              i++
            return
          ), ((err, tks) ->
            throw err  if err
            provider.cleanRequestTokens client.consumer_key, this
            return
          ), ((err) ->
            throw err  if err
            RequestToken.search
              consumer_key: client.consumer_key
            , this
            return
          ), (err, rts) ->
            if err
              cb err, null
            else
              after = rts
              cb null,
                client: client
                before: before
                after: after
                outdated: outdated

            return

          return

        "it works": (err, res) ->
          assert.ifError err
          assert.isObject res
          assert.include res, "client"
          assert.include res, "before"
          assert.include res, "after"
          assert.include res, "outdated"
          return

        "some were deleted": (err, res) ->
          b = res.before
          a = res.after
          o = res.outdated
          i = undefined
          matchT = (tok) ->
            (rt) ->
              rt.token is tok

          i = 0
          while i < b.length
            if o[b[i].token]
              assert.isUndefined a[b[i].token]
            else
              assert.isTrue a.some(matchT(b[i].token))
            i++
          return

        teardown: (res) ->
          i = undefined
          id = undefined
          res.client.del ignore  if res.client and res.client.del
          if res.after
            for id of res.after
              res.after[id].del ignore
          return

      "and we use cleanRequestTokens() on a consumer key with only out-of-date tokens":
        topic: (provider) ->
          cb = @callback
          client = undefined
          before = undefined
          after = undefined
          Step (->
            Client.create
              title: "Only out-of-date requests app"
            , this
            return
          ), ((err, results) ->
            i = undefined
            group = @group()
            throw err  if err
            client = results
            i = 0
            while i < 10
              provider.generateRequestToken client.consumer_key, "http://localhost/callback", group()
              i++
            return
          ), ((err, rts) ->
            i = undefined
            touched = Date(Date.now() - 10 * 24 * 3600)
            bank = RequestToken.bank()
            group = @group()
            throw err  if err
            before = rts
            i = 0
            while i < 10
              bank.update "requesttoken", before[i].token,
                updated: touched
              , group()
              i++
            return
          ), ((err, tks) ->
            throw err  if err
            provider.cleanRequestTokens client.consumer_key, this
            return
          ), ((err) ->
            throw err  if err
            RequestToken.search
              consumer_key: client.consumer_key
            , this
            return
          ), (err, rts) ->
            if err
              cb err, null
            else
              after = rts
              cb null,
                client: client
                before: before
                after: after

            return

          return

        "it works": (err, res) ->
          assert.ifError err
          assert.isObject res
          assert.include res, "client"
          assert.include res, "before"
          assert.include res, "after"
          return

        "all were deleted": (err, res) ->
          assert.isEmpty res.after
          return

        teardown: (res) ->
          i = undefined
          res.client.del ignore  if res.client and res.client.del
          return
)["export"] module

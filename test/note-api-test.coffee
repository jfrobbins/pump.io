# note-api-test.js
#
# Test posting a note
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
Browser = require("zombie")
httputil = require("./lib/http")
oauthutil = require("./lib/oauth")
setupApp = oauthutil.setupApp
register = oauthutil.register
newCredentials = oauthutil.newCredentials
newPair = oauthutil.newPair
newClient = oauthutil.newClient
ignore = (err) ->

suite = vows.describe("Post note API test")
makeCred = (cl, pair) ->
  consumer_key: cl.client_id
  consumer_secret: cl.client_secret
  token: pair.token
  token_secret: pair.token_secret

pairOf = (user) ->
  token: user.token
  token_secret: user.secret


# A batch for testing the read access to the API
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

  "and we get a new client":
    topic: ->
      cb = @callback
      newClient (err, cl) ->
        cb err, cl
        return

      return

    "it works": (err, cl) ->
      assert.ifError err
      assert.isObject cl
      return

    "and we make a new user":
      topic: (cl) ->
        cb = @callback
        register cl, "frodo", "i{heart}sam", (err, user) ->
          cb err, user
          return

        return

      "it works": (err, user) ->
        assert.ifError err
        assert.isObject user
        return

      "and we post a note":
        topic: (user, cl) ->
          cb = @callback
          pair = pairOf(user)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "I'm so scared!"

          cred = makeCred(cl, pair)
          httputil.postJSON "http://localhost:4815/api/user/frodo/feed", cred, act, (err, act, result) ->
            cb err, act
            return

          return

        "it works": (err, act) ->
          assert.ifError err
          return

        "results look right": (err, act) ->
          assert.isObject act
          assert.include act, "id"
          assert.isString act.id
          assert.include act, "actor"
          assert.isObject act.actor
          assert.include act.actor, "id"
          assert.isString act.actor.id
          assert.include act, "verb"
          assert.isString act.verb
          assert.include act, "object"
          assert.isObject act.object
          assert.include act.object, "id"
          assert.isString act.object.id
          assert.include act, "published"
          assert.isString act.published
          assert.include act, "updated"
          assert.isString act.updated
          return

        "results are what we posted": (err, act) ->
          assert.equal act.verb, "post"
          assert.equal act.object.content, "I'm so scared!"
          assert.equal act.object.objectType, "note"
          return

        "and we check the actor":
          topic: (act, user, cl) ->
            act: act
            user: user

          "it matches our user": (res) ->
            act = res.act
            user = res.user
            assert.equal act.actor.id, user.profile.id
            return

        "and we fetch the posted note":
          topic: (act, user, cl) ->
            cb = @callback
            pair = pairOf(user)
            cred = makeCred(cl, pair)
            
            # ID == JSON representation URL
            httputil.getJSON act.object.id, cred, (err, note) ->
              cb err, note, act
              return

            return

          "it works": (err, note, act) ->
            assert.ifError err
            assert.isObject note
            return

          "results look right": (err, note, act) ->
            assert.ifError err
            assert.isObject note
            assert.include note, "id"
            assert.isString note.id
            assert.include note, "published"
            assert.isString note.published
            assert.include note, "updated"
            assert.isString note.updated
            assert.include note, "author"
            assert.isObject note.author
            assert.include note.author, "id"
            assert.isString note.author.id
            assert.include note.author, "displayName"
            assert.isString note.author.displayName
            assert.include note.author, "objectType"
            assert.isString note.author.objectType
            return

          "results don't leak private members": (err, note, act) ->
            assert.ifError err
            assert.isObject note
            assert.isFalse _.has(note, "_uuid")
            return

          "results are what we posted": (err, note, act) ->
            assert.equal note.content, "I'm so scared!"
            assert.equal note.objectType, "note"
            assert.equal note.id, act.object.id
            assert.equal note.published, act.object.published
            assert.equal note.updated, act.object.updated
            assert.equal note.author.id, act.actor.id
            assert.equal note.author.displayName, act.actor.displayName
            assert.equal note.author.objectType, act.actor.objectType
            return

    "and we post a note and then delete it":
      topic: (cl) ->
        callback = @callback
        cred = undefined
        Step (->
          newPair cl, "saruman", "orthanc1", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "How dare you!"

          httputil.postJSON "http://localhost:4815/api/user/saruman/feed", cred, act, this
          return
        ), ((err, post, result) ->
          throw err  if err
          del =
            verb: "delete"
            object: post.object

          httputil.postJSON "http://localhost:4815/api/user/saruman/feed", cred, del, this
          return
        ), (err, del, result) ->
          if err
            callback err, null, null
          else
            callback null, del, cred
          return

        return

      "it works": (err, del, cred) ->
        assert.ifError err
        return

      "and we retrieve the deleted note":
        topic: (del, cred) ->
          callback = @callback
          url = del.object.id
          httputil.getJSON url, cred, (err, obj, res) ->
            if err and err.statusCode is 410
              callback null
            else if err
              callback err
            else
              callback new Error("Unexpected success")
            return

          return

        "it is 410 Gone": (err) ->
          assert.ifError err
          return

    "and we post a note and then update it":
      topic: (cl) ->
        callback = @callback
        feed = "http://localhost:4815/api/user/radagast/feed"
        cred = undefined
        Step (->
          newPair cl, "radagast", "i+like+birds", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "I like squirrels."

          httputil.postJSON feed, cred, act, this
          return
        ), ((err, post, result) ->
          throw err  if err
          upd =
            verb: "update"
            object:
              id: post.object.id
              objectType: "note"
              content: "I like raccoons."

          httputil.postJSON feed, cred, upd, this
          return
        ), (err, upd, result) ->
          if err
            callback err, null, null
          else
            callback null, upd, cred
          return

        return

      "it works": (err, del, cred) ->
        assert.ifError err
        return

      "and we retrieve the updated note":
        topic: (upd, cred) ->
          callback = @callback
          url = upd.object.id
          httputil.getJSON url, cred, (err, obj, res) ->
            callback err, obj
            return

          return

        "it works": (err, obj) ->
          assert.ifError err
          return

        "it has the updated content": (err, obj) ->
          assert.ifError err
          assert.isObject obj
          assert.include obj, "content"
          assert.isString obj.content
          assert.equal obj.content, "I like raccoons."
          return

    "and we post a note and then PUT to it":
      topic: (cl) ->
        callback = @callback
        feed = "http://localhost:4815/api/user/merry/feed"
        cred = undefined
        Step (->
          newPair cl, "merry", "hobbit:weed", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "I like weed."

          httputil.postJSON feed, cred, act, this
          return
        ), ((err, post, result) ->
          throw err  if err
          object = _(post.object).clone()
          object.content = "I <strong>really</strong> like weed."
          httputil.putJSON object.links.self.href, cred, object, this
          return
        ), (err, upd, result) ->
          if err
            callback err, null, null
          else
            callback null, upd, cred
          return

        return

      "it works": (err, upd, cred) ->
        assert.ifError err
        return

      "and we retrieve the updated note":
        topic: (upd, cred) ->
          callback = @callback
          url = upd.links.self.href
          httputil.getJSON url, cred, (err, obj, res) ->
            callback err, obj
            return

          return

        "it works": (err, obj) ->
          assert.ifError err
          return

        "it has the updated content": (err, obj) ->
          assert.ifError err
          assert.isObject obj
          assert.include obj, "content"
          assert.isString obj.content
          assert.equal "I <strong>really</strong> like weed.", obj.content
          return

      "and we retrieve the user's feed":
        topic: (upd, cred) ->
          callback = @callback
          url = "http://localhost:4815/api/user/merry/feed"
          httputil.getJSON url, cred, (err, obj, res) ->
            callback err, obj
            return

          return

        "it works": (err, feed) ->
          assert.ifError err
          return

        "it has the update activity": (err, feed) ->
          assert.ifError err
          assert.isObject feed
          assert.include feed, "items"
          assert.isArray feed.items
          assert.greater feed.items.length, 0
          assert.isObject feed.items[0]
          assert.include feed.items[0], "verb"
          assert.equal "update", feed.items[0].verb
          assert.include feed.items[0], "object"
          assert.include feed.items[0].object, "id"
          assert.equal feed.items[0].object.id, feed.items[1].object.id
          return

    "and we post a note and then DELETE it":
      topic: (cl) ->
        callback = @callback
        feed = "http://localhost:4815/api/user/pippin/feed"
        url = undefined
        cred = undefined
        Step (->
          newPair cl, "pippin", "2nd*breakfast", this
          return
        ), ((err, pair) ->
          act = undefined
          throw err  if err
          cred = makeCred(cl, pair)
          act =
            verb: "post"
            object:
              objectType: "note"
              content: "I'm hungry."

          httputil.postJSON feed, cred, act, this
          return
        ), ((err, post, result) ->
          throw err  if err
          url = post.object.links.self.href
          httputil.delJSON url, cred, this
          return
        ), (err, res, result) ->
          if err
            callback err, null, null
          else
            callback null, url, cred
          return

        return

      "it works": (err, url, cred) ->
        assert.ifError err
        return

      "and we retrieve the deleted note":
        topic: (url, cred) ->
          callback = @callback
          httputil.getJSON url, cred, (err, obj, res) ->
            if err and err.statusCode is 410
              callback null
            else if err
              callback err
            else
              callback new Error("Unexpected success!")
            return

          return

        "it is 410 Gone": (err) ->
          assert.ifError err
          return

      "and we retrieve the user's feed":
        topic: (upd, cred) ->
          callback = @callback
          url = "http://localhost:4815/api/user/pippin/feed"
          httputil.getJSON url, cred, (err, obj, res) ->
            callback err, obj
            return

          return

        "it works": (err, feed) ->
          assert.ifError err
          return

        "it has the delete activity": (err, feed) ->
          assert.ifError err
          assert.isObject feed
          assert.include feed, "items"
          assert.isArray feed.items
          assert.greater feed.items.length, 0
          assert.isObject feed.items[0]
          assert.include feed.items[0], "verb"
          assert.equal "delete", feed.items[0].verb
          assert.include feed.items[0], "object"
          assert.include feed.items[0].object, "id"
          assert.equal feed.items[0].object.id, feed.items[1].object.id
          return

suite["export"] module

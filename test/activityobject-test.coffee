# activityobject-test.js
#
# Test the activityobject module's class methods
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
Databank = databank.Databank
DatabankObject = databank.DatabankObject
schema = require("../lib/schema").schema
URLMaker = require("../lib/urlmaker").URLMaker
suite = vows.describe("activityobject class interface")
tc = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json")))
suite.addBatch "When we require the activityobject module":
  topic: ->
    cb = @callback
    
    # Need this to make IDs
    URLMaker.hostname = "example.net"
    
    # Dummy databank
    tc.params.schema = schema
    db = Databank.get(tc.driver, tc.params)
    db.connect {}, (err) ->
      mod = undefined
      DatabankObject.bank = db
      mod = require("../lib/model/activityobject") or null
      cb null, mod
      return

    return

  "we get a module": (mod) ->
    assert.isObject mod
    return

  "and we get its UnknownTypeError member":
    topic: (mod) ->
      mod.UnknownTypeError

    "it exists": (ActivityObject) ->
      assert.isFunction ActivityObject
      return

  "and we get its ActivityObject member":
    topic: (mod) ->
      mod.ActivityObject

    "it exists": (ActivityObject) ->
      assert.isFunction ActivityObject
      return

    "it has a makeURI member": (ActivityObject) ->
      assert.isFunction ActivityObject.makeURI
      return

    "it has a toClass member": (ActivityObject) ->
      assert.isFunction ActivityObject.toClass
      return

    "it has a toObject member": (ActivityObject) ->
      assert.isFunction ActivityObject.toObject
      return

    "it has a getObject member": (ActivityObject) ->
      assert.isFunction ActivityObject.getObject
      return

    "it has a createObject member": (ActivityObject) ->
      assert.isFunction ActivityObject.createObject
      return

    "it has an ensureObject member": (ActivityObject) ->
      assert.isFunction ActivityObject.ensureObject
      return

    "it has a compressProperty member": (ActivityObject) ->
      assert.isFunction ActivityObject.compressProperty
      return

    "it has an ensureProperty member": (ActivityObject) ->
      assert.isFunction ActivityObject.ensureProperty
      return

    "it has an expandProperty member": (ActivityObject) ->
      assert.isFunction ActivityObject.expandProperty
      return

    "it has an ensureArray member": (ActivityObject) ->
      assert.isFunction ActivityObject.ensureArray
      return

    "it has a getObjectStream member": (ActivityObject) ->
      assert.isFunction ActivityObject.getObjectStream
      return

    "it has a sameID member": (ActivityObject) ->
      assert.isFunction ActivityObject.sameID
      return

    "it has a canonicalID member": (ActivityObject) ->
      assert.isFunction ActivityObject.canonicalID
      return

    "it has an objectTypes member": (ActivityObject) ->
      assert.isArray ActivityObject.objectTypes
      return

    "it has constant-ish members for known types": (ActivityObject) ->
      assert.equal ActivityObject.ALERT, "alert"
      assert.equal ActivityObject.APPLICATION, "application"
      assert.equal ActivityObject.ARTICLE, "article"
      assert.equal ActivityObject.AUDIO, "audio"
      assert.equal ActivityObject.BADGE, "badge"
      assert.equal ActivityObject.BINARY, "binary"
      assert.equal ActivityObject.BOOKMARK, "bookmark"
      assert.equal ActivityObject.COLLECTION, "collection"
      assert.equal ActivityObject.COMMENT, "comment"
      assert.equal ActivityObject.DEVICE, "device"
      assert.equal ActivityObject.EVENT, "event"
      assert.equal ActivityObject.FILE, "file"
      assert.equal ActivityObject.GAME, "game"
      assert.equal ActivityObject.GROUP, "group"
      assert.equal ActivityObject.IMAGE, "image"
      assert.equal ActivityObject.ISSUE, "issue"
      assert.equal ActivityObject.JOB, "job"
      assert.equal ActivityObject.NOTE, "note"
      assert.equal ActivityObject.OFFER, "offer"
      assert.equal ActivityObject.ORGANIZATION, "organization"
      assert.equal ActivityObject.PAGE, "page"
      assert.equal ActivityObject.PERSON, "person"
      assert.equal ActivityObject.PLACE, "place"
      assert.equal ActivityObject.PROCESS, "process"
      assert.equal ActivityObject.PRODUCT, "product"
      assert.equal ActivityObject.QUESTION, "question"
      assert.equal ActivityObject.REVIEW, "review"
      assert.equal ActivityObject.SERVICE, "service"
      assert.equal ActivityObject.TASK, "task"
      assert.equal ActivityObject.VIDEO, "video"
      return

    "and we make a new URI":
      topic: (ActivityObject) ->
        ActivityObject.makeURI ActivityObject.AUDIO, "AAAAAAAAAAAAAAAAAAAAAAA"

      "it returns a string": (uri) ->
        assert.isString uri
        return

    "and we get a class by typename":
      topic: (ActivityObject) ->
        ActivityObject.toClass ActivityObject.VIDEO

      "it returns the right one": (Video) ->
        assert.equal Video, require("../lib/model/video").Video
        return

    "and we get a class by unknown typename":
      topic: (ActivityObject) ->
        ActivityObject.toClass "http://underwear.example/type/boxer-briefs"

      "it returns the Other": (Other) ->
        assert.equal Other, require("../lib/model/other").Other
        return

    "and we get an object by properties":
      topic: (ActivityObject) ->
        props =
          objectType: ActivityObject.REVIEW
          id: "http://example.org/reviews/1"
          content: "I hate your blog."

        ActivityObject.toObject props

      "it exists": (review) ->
        assert.isObject review
        return

      "it is the right type": (review) ->
        assert.instanceOf review, require("../lib/model/review").Review
        return

      "it has the right properties": (review) ->
        assert.equal review.objectType, "review"
        assert.equal review.id, "http://example.org/reviews/1"
        assert.equal review.content, "I hate your blog."
        return

      "it has an expand() method": (review) ->
        assert.isFunction review.expand
        return

      "it has a favoritedBy() method": (review) ->
        assert.isFunction review.favoritedBy
        return

      "it has an unfavoritedBy() method": (review) ->
        assert.isFunction review.unfavoritedBy
        return

      "it has a getFavoriters() method": (review) ->
        assert.isFunction review.getFavoriters
        return

      "it has a favoritersCount() method": (review) ->
        assert.isFunction review.favoritersCount
        return

      "it has an expandFeeds() method": (review) ->
        assert.isFunction review.expandFeeds
        return

      "it has an efface() method": (review) ->
        assert.isFunction review.efface
        return

      "it has an isFollowable() method": (review) ->
        assert.isFunction review.isFollowable
        return

      "it has a getSharesStream() method": (review) ->
        assert.isFunction review.getSharesStream
        return

      "it has a sharesCount() method": (review) ->
        assert.isFunction review.sharesCount
        return

    "and we get a non-activityobject model object by its properties":
      topic: (ActivityObject) ->
        props =
          objectType: "user"
          nickname: "evan"

        ActivityObject.toObject props

      "it is an Other": (user) ->
        assert.instanceOf user, require("../lib/model/other").Other
        assert.equal user.objectType, "user"
        return

    "and we get a weird made-up object by its properties":
      topic: (ActivityObject) ->
        props =
          objectType: "http://condiment.example/type/spice"
          displayName: "Cinnamon"

        ActivityObject.toObject props

      "it is an Other": (cinnamon) ->
        assert.instanceOf cinnamon, require("../lib/model/other").Other
        assert.equal cinnamon.objectType, "http://condiment.example/type/spice"
        return

    "and we create an activityobject object":
      topic: (ActivityObject) ->
        props =
          objectType: ActivityObject.ARTICLE
          content: "Blah blah blah."

        ActivityObject.createObject props, @callback
        return

      teardown: (article) ->
        if article and article.del
          article.del (err) ->

        return

      "it works": (err, article) ->
        assert.ifError err
        return

      "it exists": (err, article) ->
        assert.isObject article
        return

      "it has the right class": (err, article) ->
        assert.instanceOf article, require("../lib/model/article").Article
        return

      "it has the right passed-in attributes": (err, article) ->
        assert.equal article.objectType, "article"
        assert.equal article.content, "Blah blah blah."
        return

      "it has the right auto-created attributes": (err, article) ->
        assert.isString article.id
        assert.isString article.published
        assert.isString article.updated
        return

      "and we get the same object":
        topic: (article, ActivityObject) ->
          ActivityObject.getObject ActivityObject.ARTICLE, article.id, @callback
          return

        "it works": (err, article) ->
          assert.ifError err
          return

        "it exists": (err, article) ->
          assert.isObject article
          return

        "it has the right class": (err, article) ->
          assert.instanceOf article, require("../lib/model/article").Article
          return

        "it has the right passed-in attributes": (err, article) ->
          assert.equal article.objectType, "article"
          assert.equal article.content, "Blah blah blah."
          return

        "it has the right auto-created attributes": (err, article) ->
          assert.isString article.id
          assert.isString article.published
          assert.isString article.updated
          return

    "and we create an activityobject of unknown type":
      topic: (ActivityObject) ->
        props =
          objectType: "http://orange.example/type/seed"
          displayName: "Seed #3451441"

        ActivityObject.createObject props, @callback
        return

      "it works": (err, seed) ->
        assert.ifError err
        assert.isObject seed
        assert.instanceOf seed, require("../lib/model/other").Other
        assert.equal seed.objectType, "http://orange.example/type/seed"
        return

    "and we ensure a new activityobject object":
      topic: (ActivityObject) ->
        props =
          id: "urn:uuid:2b7cc63f-dd9a-438f-b6d3-846fee2634bf"
          objectType: ActivityObject.GROUP
          displayName: "pump.io Devs"

        ActivityObject.ensureObject props, @callback
        return

      teardown: (group) ->
        if group and group.del
          group.del (err) ->

        return

      "it works": (err, article) ->
        assert.ifError err
        return

      "it exists": (err, group) ->
        assert.isObject group
        return

      "it has the right class": (err, group) ->
        assert.instanceOf group, require("../lib/model/group").Group
        return

      "it has the right passed-in attributes": (err, group) ->
        assert.equal group.objectType, "group"
        assert.equal group.displayName, "pump.io Devs"
        return

      "it has the right auto-created attributes": (err, group) ->
        assert.isString group.id
        return

    "and we ensure an existing activityobject object":
      topic: (ActivityObject) ->
        cb = @callback
        Comment = require("../lib/model/comment").Comment
        props =
          objectType: ActivityObject.COMMENT
          content: "FIRST POST"
          inReplyTo:
            objectType: ActivityObject.ARTICLE
            id: "http://example.net/articles/3"

        Comment.create props, (err, comment) ->
          p = {}
          if err
            cb err, null
          else
            DatabankObject.copy p, comment
            ActivityObject.ensureObject p, cb
          return

        return

      teardown: (comment) ->
        if comment and comment.del
          comment.del (err) ->

        return

      "it works": (err, comment) ->
        assert.ifError err
        return

      "it exists": (err, comment) ->
        assert.isObject comment
        return

      "it has the right class": (err, comment) ->
        assert.instanceOf comment, require("../lib/model/comment").Comment
        return

      "it has the right passed-in attributes": (err, comment) ->
        assert.equal comment.objectType, "comment"
        assert.equal comment.content, "FIRST POST"
        assert.equal comment.inReplyTo.id, "http://example.net/articles/3"
        assert.equal comment.inReplyTo.objectType, "article"
        return

      "it has the right auto-created attributes": (err, comment) ->
        assert.isString comment.id
        assert.isString comment.published
        assert.isString comment.updated
        return

    "and we ensure an activityobject of unrecognized type":
      topic: (ActivityObject) ->
        props =
          id: "urn:uuid:4fcc9eda-0469-11e2-a4d5-70f1a154e1aa"
          objectType: "http://utensil.example/type/spoon"
          displayName: "My spoon"

        ActivityObject.ensureObject props, @callback
        return

      "it works": (err, article) ->
        assert.ifError err
        return

      "it exists": (err, spoon) ->
        assert.ifError err
        assert.isObject spoon
        return

      "it has the right class": (err, spoon) ->
        assert.instanceOf spoon, require("../lib/model/other").Other
        assert.equal spoon.objectType, "http://utensil.example/type/spoon"
        return

    "and we ensure an existing object property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        Person = require("../lib/model/person").Person
        image = new Image(
          author:
            id: "urn:uuid:c3a7bd6e-fecb-11e2-ae9d-32b36b1a1850"
            displayName: "Glen Miller"
            objectType: "person"

          url: "http://example.net/images/2.jpg"
        )
        ActivityObject.ensureProperty image, "author", (err) ->
          if err
            cb err, null
          else
            cb null, image
          return

        return

      "it works": (err, image) ->
        assert.ifError err
        return

      "the property is ensured": (err, image) ->
        assert.ifError err
        assert.include image, "author"
        assert.isObject image.author
        assert.instanceOf image.author, require("../lib/model/person").Person
        assert.include image.author, "id"
        assert.isString image.author.id
        assert.equal image.author.id, "urn:uuid:c3a7bd6e-fecb-11e2-ae9d-32b36b1a1850"
        assert.include image.author, "objectType"
        assert.isString image.author.objectType
        assert.equal image.author.objectType, "person"
        assert.equal image.author.displayName, "Glen Miller"
        return

    "and we compress an existing object property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        Person = require("../lib/model/person").Person
        image = new Image(
          author:
            id: "urn:uuid:8a9d0e92-3210-4ea3-920f-3950ca8d5306"
            displayName: "Barney Miller"
            objectType: "person"

          url: "http://example.net/images/1.jpg"
        )
        ActivityObject.compressProperty image, "author", (err) ->
          if err
            cb err, null
          else
            cb null, image
          return

        return

      "it works": (err, image) ->
        assert.ifError err
        return

      "the property is compressed": (err, image) ->
        assert.ifError err
        assert.include image, "author"
        assert.isObject image.author
        assert.instanceOf image.author, require("../lib/model/person").Person
        assert.include image.author, "id"
        assert.isString image.author.id
        assert.equal image.author.id, "urn:uuid:8a9d0e92-3210-4ea3-920f-3950ca8d5306"
        assert.include image.author, "objectType"
        assert.isString image.author.objectType
        assert.equal image.author.objectType, "person"
        assert.isFalse _(image.author).has("displayName")
        return

    "and we compress a non-existent object property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        image = new Image(url: "http://example.net/images/2.jpg")
        ActivityObject.compressProperty image, "author", (err) ->
          if err
            cb err, null
          else
            cb null, image
          return

        return

      "it works": (err, image) ->
        assert.ifError err
        return

      "the property remains non-existent": (err, image) ->
        assert.ifError err
        assert.isFalse _(image).has("author")
        return

    "and we expand an existing object property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        Person = require("../lib/model/person").Person
        image = undefined
        Step (->
          Person.create
            id: "urn:uuid:bbd313d1-6f8d-4d72-bc05-bde69ba795d7"
            displayName: "Theo Kojak"
          , this
          return
        ), ((err, person) ->
          throw err  if err
          image = new Image(
            url: "http://example.net/images/1.jpg"
            author:
              id: person.id
              objectType: "person"
          )
          ActivityObject.expandProperty image, "author", this
          return
        ), (err) ->
          if err
            cb err, null
          else
            cb null, image
          return

        return

      "it works": (err, image) ->
        assert.ifError err
        return

      "the property is expanded": (err, image) ->
        assert.ifError err
        assert.include image, "author"
        assert.isObject image.author
        assert.instanceOf image.author, require("../lib/model/person").Person
        assert.include image.author, "id"
        assert.isString image.author.id
        assert.equal image.author.id, "urn:uuid:bbd313d1-6f8d-4d72-bc05-bde69ba795d7"
        assert.include image.author, "objectType"
        assert.isString image.author.objectType
        assert.equal image.author.objectType, "person"
        assert.include image.author, "displayName"
        assert.isString image.author.displayName
        assert.equal image.author.displayName, "Theo Kojak"
        return

    "and we expand a non-existent object property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        image = new Image(url: "http://example.net/images/4.jpg")
        ActivityObject.expandProperty image, "author", (err) ->
          if err
            cb err, null
          else
            cb null, image
          return

        return

      "it works": (err, image) ->
        assert.ifError err
        return

      "the property remains non-existent": (err, image) ->
        assert.ifError err
        assert.isFalse _(image).has("author")
        return

    "and we compress a scalar property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        image = new Image(url: "http://example.net/images/5.jpg")
        ActivityObject.compressProperty image, "url", (err) ->
          if err
            cb null, image
          else
            cb new Error("Unexpected success"), null
          return

        return

      "it fails correctly": (err, image) ->
        assert.ifError err
        return

      "the property remains non-existent": (err, image) ->
        assert.ifError err
        assert.isString image.url
        assert.equal image.url, "http://example.net/images/5.jpg"
        return

    "and we expand a scalar property of an object":
      topic: (ActivityObject) ->
        cb = @callback
        Image = require("../lib/model/image").Image
        image = new Image(url: "http://example.net/images/6.jpg")
        ActivityObject.expandProperty image, "url", (err) ->
          if err
            cb null, image
          else
            cb new Error("Unexpected success"), null
          return

        return

      "it fails correctly": (err, image) ->
        assert.ifError err
        return

      "the property remains non-existent": (err, image) ->
        assert.ifError err
        assert.isString image.url
        assert.equal image.url, "http://example.net/images/6.jpg"
        return

    "and we create an activityobject with an author":
      topic: (ActivityObject) ->
        cb = @callback
        Note = require("../lib/model/note").Note
        Person = require("../lib/model/person").Person
        props =
          objectType: ActivityObject.NOTE
          content: "HELLO WORLD"

        author = undefined
        Step (->
          Person.create
            displayName: "peter"
            preferredUsername: "p65"
          , this
          return
        ), ((err, person) ->
          throw err  if err
          author = props.author = person
          Note.create props, this
          return
        ), (err, note) ->
          cb err, note, author
          return

        return

      "it works": (err, object, author) ->
        assert.ifError err
        assert.isObject object
        return

      "results contain the author information": (err, object, author) ->
        assert.ifError err
        assert.isObject object.author
        assert.equal object.author.id, author.id
        assert.equal object.author.objectType, author.objectType
        assert.equal object.author.displayName, author.displayName
        assert.equal object.author.preferredUsername, author.preferredUsername
        return

    "and we create an activityobject with an author reference":
      topic: (ActivityObject) ->
        cb = @callback
        Note = require("../lib/model/note").Note
        Person = require("../lib/model/person").Person
        props =
          objectType: ActivityObject.NOTE
          content: "HELLO WORLD"

        author = undefined
        Step (->
          Person.create
            displayName: "quincy"
            preferredUsername: "qbert"
          , this
          return
        ), ((err, person) ->
          throw err  if err
          author = person
          props.author =
            id: person.id
            objectType: person.objectType

          Note.create props, this
          return
        ), (err, note) ->
          cb err, note, author
          return

        return

      "it works": (err, object, author) ->
        assert.ifError err
        assert.isObject object
        return

      "results contain the author information": (err, object, author) ->
        assert.ifError err
        assert.isObject object.author
        assert.equal object.author.id, author.id
        assert.equal object.author.objectType, author.objectType
        assert.equal object.author.displayName, author.displayName
        assert.equal object.author.preferredUsername, author.preferredUsername
        return

    "and we update an activityobject with an author":
      topic: (ActivityObject) ->
        cb = @callback
        Note = require("../lib/model/note").Note
        Person = require("../lib/model/person").Person
        props =
          objectType: ActivityObject.NOTE
          content: "HELLO WORLD"

        author = undefined
        Step (->
          Person.create
            displayName: "randy"
            preferredUsername: "rman99"
          , this
          return
        ), ((err, person) ->
          throw err  if err
          author = person
          props.author = person
          Note.create props, this
          return
        ), ((err, note) ->
          throw err  if err
          note.update
            summary: "A helpful greeting"
          , this
          return
        ), (err, note) ->
          cb err, note, author
          return

        return

      "it works": (err, object, author) ->
        assert.ifError err
        assert.isObject object
        return

      "results contain the author information": (err, object, author) ->
        assert.ifError err
        assert.isObject object.author
        assert.equal object.author.id, author.id
        assert.equal object.author.objectType, author.objectType
        assert.equal object.author.displayName, author.displayName
        assert.equal object.author.preferredUsername, author.preferredUsername
        return

    "and we update an activityobject with an author reference":
      topic: (ActivityObject) ->
        cb = @callback
        Note = require("../lib/model/note").Note
        Person = require("../lib/model/person").Person
        props =
          objectType: ActivityObject.NOTE
          content: "HELLO WORLD"

        author = undefined
        Step (->
          Person.create
            displayName: "steven"
            preferredUsername: "billabong"
          , this
          return
        ), ((err, person) ->
          throw err  if err
          author = person
          props.author = person
          Note.create props, this
          return
        ), ((err, note) ->
          throw err  if err
          note.author =
            id: note.author.id
            objectType: note.author.objectType

          note.update
            summary: "A helpful greeting"
          , this
          return
        ), (err, note) ->
          cb err, note, author
          return

        return

      "it works": (err, object, author) ->
        assert.ifError err
        assert.isObject object
        return

      "results contain the author information": (err, object, author) ->
        assert.ifError err
        assert.isObject object.author
        assert.equal object.author.id, author.id
        assert.equal object.author.objectType, author.objectType
        assert.equal object.author.displayName, author.displayName
        assert.equal object.author.preferredUsername, author.preferredUsername
        return

    "and we get a non-existent stream of objects":
      topic: (ActivityObject) ->
        ActivityObject.getObjectStream "person", "nonexistent", 0, 20, @callback
        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "it returns an empty array": (err, objects) ->
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 0
        return

    "and we get an empty object stream":
      topic: (ActivityObject) ->
        cb = @callback
        Stream = require("../lib/model/stream").Stream
        Step (->
          Stream.create
            name: "activityobject-test-1"
          , this
          return
        ), (err, stream) ->
          throw err  if err
          ActivityObject.getObjectStream "person", "activityobject-test-1", 0, 20, cb
          return

        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "it returns an empty array": (err, objects) ->
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 0
        return

    "and we get an object stream with stuff in it":
      topic: (ActivityObject) ->
        cb = @callback
        Stream = require("../lib/model/stream").Stream
        Service = require("../lib/model/service").Service
        stream = undefined
        Step (->
          Stream.create
            name: "activityobject-test-2"
          , this
          return
        ), ((err, results) ->
          i = undefined
          group = @group()
          throw err  if err
          stream = results
          i = 0
          while i < 100
            Service.create
              displayName: "Service #" + i
            , group()
            i++
          return
        ), ((err, services) ->
          i = undefined
          group = @group()
          throw err  if err
          i = 0
          while i < 100
            stream.deliver services[i].id, group()
            i++
          return
        ), (err) ->
          throw err  if err
          ActivityObject.getObjectStream "service", "activityobject-test-2", 0, 20, cb
          return

        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "it returns a non-empty array": (err, objects) ->
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 20
        return

      "members are the correct type": (err, objects) ->
        Service = require("../lib/model/service").Service
        assert.ifError err
        i = 0

        while i < objects.length
          assert.isObject objects[i]
          assert.instanceOf objects[i], Service
          i++
        return

    "and we get the favoriters of a brand-new object":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        Step (->
          Place.create
            displayName: "Mount Everest"
            position: "+27.5916+086.5640+8850/"
          , this
          return
        ), ((err, place) ->
          throw err  if err
          place.getFavoriters 0, 20, this
          return
        ), (err, favers) ->
          if err
            cb err, null
          else
            cb null, favers
          return

        return

      "it works": (err, objects) ->
        assert.ifError err
        return

      "it returns an empty array": (err, objects) ->
        assert.ifError err
        assert.isArray objects
        assert.lengthOf objects, 0
        return

    "and we get the favoriters count of a brand-new object":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        Step (->
          Place.create
            displayName: "South Pole"
            position: "-90.0000+0.0000/"
          , this
          return
        ), ((err, place) ->
          throw err  if err
          place.favoritersCount this
          return
        ), (err, count) ->
          if err
            cb err, null
          else
            cb null, count
          return

        return

      "it works": (err, count) ->
        assert.ifError err
        return

      "it returns zero": (err, count) ->
        assert.ifError err
        assert.equal count, 0
        return

    "and we add a favoriter for an object":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        Person = require("../lib/model/person").Person
        place = null
        person = null
        Step (->
          Place.create
            displayName: "North Pole"
            position: "+90.0000+0.0000/"
          , @parallel()
          Person.create
            displayName: "Robert Peary"
          , @parallel()
          return
        ), ((err, results1, results2) ->
          throw err  if err
          place = results1
          person = results2
          place.favoritedBy person.id, this
          return
        ), (err) ->
          if err
            cb err, null, null
          else
            cb null, place, person
          return

        return

      "it worked": (err, place, person) ->
        assert.ifError err
        return

      "and we get its favoriters list":
        topic: (place, person) ->
          cb = @callback
          place.getFavoriters 0, 20, (err, favers) ->
            cb err, favers, person
            return

          return

        "it worked": (err, favers, person) ->
          assert.ifError err
          return

        "it is the right size": (err, favers, person) ->
          assert.ifError err
          assert.isArray favers
          assert.lengthOf favers, 1
          return

        "it contains our data": (err, favers, person) ->
          assert.ifError err
          assert.equal favers[0].id, person.id
          return

      "and we get its favoriters count":
        topic: (place, person) ->
          place.favoritersCount @callback
          return

        "it works": (err, count) ->
          assert.ifError err
          return

        "it returns one": (err, count) ->
          assert.ifError err
          assert.equal count, 1
          return

    "and we add then remove a favoriter for an object":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        Person = require("../lib/model/person").Person
        place = null
        person = null
        Step (->
          Place.create
            displayName: "Montreal"
            position: "+45.5124-73.5547/"
          , @parallel()
          Person.create
            displayName: "Evan Prodromou"
          , @parallel()
          return
        ), ((err, results1, results2) ->
          throw err  if err
          place = results1
          person = results2
          place.favoritedBy person.id, this
          return
        ), ((err) ->
          throw err  if err
          place.unfavoritedBy person.id, this
          return
        ), (err) ->
          if err
            cb err, null, null
          else
            cb null, place, person
          return

        return

      "and we get its favoriters list":
        topic: (place, person) ->
          cb = @callback
          place.getFavoriters 0, 20, (err, favers) ->
            cb err, favers, person
            return

          return

        "it worked": (err, favers, person) ->
          assert.ifError err
          return

        "it is the right size": (err, favers, person) ->
          assert.ifError err
          assert.isArray favers
          assert.lengthOf favers, 0
          return

      "and we get its favoriters count":
        topic: (place, person) ->
          place.favoritersCount @callback
          return

        "it works": (err, count) ->
          assert.ifError err
          return

        "it returns zero": (err, count) ->
          assert.ifError err
          assert.equal count, 0
          return

    "and we expand the feeds for an object":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        place = null
        Step (->
          Place.create
            displayName: "San Francisco"
            position: "+37.7771-122.4196/"
          , this
          return
        ), ((err, results) ->
          throw err  if err
          place = results
          place.expandFeeds this
          return
        ), (err) ->
          if err
            cb err, null
          else
            cb null, place
          return

        return

      "it works": (err, place) ->
        assert.ifError err
        return

      "it adds the 'likes' property": (err, place) ->
        assert.ifError err
        assert.includes place, "likes"
        assert.isObject place.likes
        assert.includes place.likes, "totalItems"
        assert.equal place.likes.totalItems, 0
        assert.includes place.likes, "url"
        assert.isString place.likes.url
        return

    "and we create then efface an object":
      topic: (ActivityObject) ->
        cb = @callback
        Comment = require("../lib/model/comment").Comment
        comment = undefined
        Step (->
          props =
            author:
              id: "mailto:evan@status.net"
              objectType: "person"

            inReplyTo:
              url: "http://scripting.com/stories/2012/07/25/anOpenTwitterlikeEcosystem.html"
              objectType: "article"

            content: "Right on, Dave."

          Comment.create props, this
          return
        ), ((err, results) ->
          throw err  if err
          comment = results
          comment.efface this
          return
        ), (err) ->
          if err
            cb err, null
          else
            cb null, comment
          return

        return

      "it works": (err, comment) ->
        assert.ifError err
        return

      "it looks right": (err, comment) ->
        assert.ifError err
        assert.ok comment.id
        assert.ok comment.objectType
        assert.ok comment.author
        assert.ok comment.inReplyTo
        assert.ok comment.published
        assert.ok comment.updated
        assert.ok comment.deleted
        assert.isUndefined comment.content
        return

    "and we canonicalize an http: ID":
      topic: (ActivityObject) ->
        ActivityObject.canonicalID "http://social.example/user/1"

      "it is unchanged": (id) ->
        assert.equal id, "http://social.example/user/1"
        return

    "and we canonicalize an https: ID":
      topic: (ActivityObject) ->
        ActivityObject.canonicalID "https://photo.example/user/1"

      "it is unchanged": (id) ->
        assert.equal id, "https://photo.example/user/1"
        return

    "and we canonicalize an acct: ID":
      topic: (ActivityObject) ->
        ActivityObject.canonicalID "acct:user@checkin.example"

      "it is unchanged": (id) ->
        assert.equal id, "acct:user@checkin.example"
        return

    "and we canonicalize a bare Webfinger":
      topic: (ActivityObject) ->
        ActivityObject.canonicalID "user@checkin.example"

      "it is unchanged": (id) ->
        assert.equal id, "acct:user@checkin.example"
        return

    "and we compare an acct: URI and a bare Webfinger":
      topic: (ActivityObject) ->
        ActivityObject.sameID "acct:user@checkin.example", "user@checkin.example"

      "it is a match": (res) ->
        assert.isTrue res
        return

    "and we check if a person is followable":
      topic: (ActivityObject) ->
        Person = require("../lib/model/person").Person
        joey = new Person(
          displayName: "Joey"
          objectType: "person"
        )
        joey.isFollowable()

      "it is": (res) ->
        assert.isTrue res
        return

    "and we check if a review is followable":
      topic: (ActivityObject) ->
        Review = require("../lib/model/review").Review
        badReview = new Review(
          displayName: "You suck"
          objectType: "review"
        )
        badReview.isFollowable()

      "it is not": (res) ->
        assert.isFalse res
        return

    "and we check if an object with an activity outbox is followable":
      topic: (ActivityObject) ->
        Review = require("../lib/model/review").Review
        badReview = new Review(
          displayName: "You suck"
          objectType: "review"
          links:
            "activity-outbox":
              href: "http://example.com/review/outbox"
        )
        badReview.isFollowable()

      "it is": (res) ->
        assert.isTrue res
        return

    "and we trim a collection":
      topic: (ActivityObject) ->
        props = likes:
          totalItems: 30
          items: [
            objectType: "person"
            id: "urn:uuid:4f9986da-0748-11e2-9deb-70f1a154e1aa"
          ]
          url: "http://social.example/api/note/10/likes"

        ActivityObject.trimCollection props, "likes"
        props

      "it works": (props) ->
        assert.include props, "likes"
        assert.isFalse _(props.likes).has("totalItems")
        assert.isFalse _(props.likes).has("items")
        assert.isTrue _(props.likes).has("url")
        return

    "and we check whether a full object is a reference":
      topic: (ActivityObject) ->
        props =
          id: "urn:uuid:32003b5c-8680-11e2-acaf-70f1a154e1aa"
          objectType: "note"
          content: "Hello, world!"

        ActivityObject.isReference props

      "it is not": (isRef) ->
        assert.isFalse isRef
        return

    "and we check whether a reference is a reference":
      topic: (ActivityObject) ->
        props =
          id: "urn:uuid:5e2daa16-8680-11e2-823c-70f1a154e1aa"
          objectType: "person"

        ActivityObject.isReference props

      "it is": (isRef) ->
        assert.isTrue isRef
        return

    "and we get a stream of favoriters":
      topic: (ActivityObject) ->
        cb = @callback
        Place = require("../lib/model/place").Place
        place = null
        Step (->
          Place.create
            displayName: "Empire State Building"
            position: "40.749-73.986/"
          , this
          return
        ), ((err, results) ->
          throw err  if err
          place = results
          place.getFavoritersStream this
          return
        ), (err, str) ->
          if err
            cb err, null
          else
            cb null, str
          return

        return

      "it works": (err, str) ->
        assert.ifError err
        assert.isObject str
        return

    "and we get the string of an object with no id":
      topic: (ActivityObject) ->
        Game = require("../lib/model/game").Game
        game = new Game(objectType: "game")
        game.toString()

      "it looks correct": (str) ->
        assert.equal str, "[game Undefined]"
        return

    "and we get the string of an object with an id":
      topic: (ActivityObject) ->
        Game = require("../lib/model/game").Game
        game = new Game(
          objectType: "game"
          id: "urn:uuid:c52b69b6-b717-11e2-9d1e-2c8158efb9e9"
        )
        game.toString()

      "it looks correct": (str) ->
        assert.equal "[game urn:uuid:c52b69b6-b717-11e2-9d1e-2c8158efb9e9]", str
        return

    "and we get a sub-schema with no arguments":
      topic: (ActivityObject) ->
        [
          ActivityObject.subSchema()
          ActivityObject
        ]

      "it looks correct": (parts) ->
        sub = parts[0]
        ActivityObject = parts[1]
        assert.deepEqual sub, ActivityObject.baseSchema
        return

    "and we get a sub-schema with removal arguments":
      topic: (ActivityObject) ->
        [
          ActivityObject.subSchema(["attachments"])
          ActivityObject
        ]

      "it looks correct": (parts) ->
        sub = parts[0]
        ActivityObject = parts[1]
        base = ActivityObject.baseSchema
        assert.deepEqual sub.pkey, base.pkey
        assert.deepEqual sub.indices, base.indices
        assert.deepEqual sub.fields, _.without(base.fields, "attachments")
        return

    "and we get a sub-schema with add arguments":
      topic: (ActivityObject) ->
        [
          ActivityObject.subSchema(null, ["members"])
          ActivityObject
        ]

      "it looks correct": (parts) ->
        sub = parts[0]
        ActivityObject = parts[1]
        base = ActivityObject.baseSchema
        assert.deepEqual sub.pkey, base.pkey
        assert.deepEqual sub.indices, base.indices
        assert.deepEqual sub.fields, _.union(base.fields, "members")
        return

    "and we get a sub-schema with remove and add arguments":
      topic: (ActivityObject) ->
        [
          ActivityObject.subSchema(["attachments"], ["members"])
          ActivityObject
        ]

      "it looks correct": (parts) ->
        sub = parts[0]
        ActivityObject = parts[1]
        base = ActivityObject.baseSchema
        assert.deepEqual sub.pkey, base.pkey
        assert.deepEqual sub.indices, base.indices
        assert.deepEqual sub.fields, _.union(_.without(base.fields, "attachments"), "members")
        return

    "and we get a sub-schema with index arguments":
      topic: (ActivityObject) ->
        [
          ActivityObject.subSchema(null, null, ["_slug"])
          ActivityObject
        ]

      "it looks correct": (parts) ->
        sub = parts[0]
        ActivityObject = parts[1]
        base = ActivityObject.baseSchema
        assert.deepEqual sub.pkey, base.pkey
        assert.deepEqual sub.indices, _.union(base.indices, ["_slug"])
        assert.deepEqual sub.fields, base.fields
        return

suite["export"] module

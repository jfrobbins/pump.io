# offer-test.js
#
# Test the offer module
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
URLMaker = require("../lib/urlmaker").URLMaker
modelBatch = require("./lib/model").modelBatch
Databank = databank.Databank
DatabankObject = databank.DatabankObject
suite = vows.describe("offer module interface")
testSchema =
  pkey: "id"
  fields: [
    "_created"
    "_uuid"
    "attachments"
    "author"
    "content"
    "displayName"
    "downstreamDuplicates"
    "id"
    "image"
    "inReplyTo"
    "likes"
    "links"
    "objectType"
    "published"
    "replies"
    "shares"
    "summary"
    "updated"
    "upstreamDuplicates"
    "url"
  ]
  indices: [
    "_uuid"
    "url"
  ]

testData =
  create:
    displayName: "25% Discount on Selected Flights"
    summary: "Certain flights are offered at a 25% discount."

  update:
    summary: "Certain flights are offered at a 25% discount; some restrictions apply."

suite.addBatch modelBatch("offer", "Offer", testSchema, testData)
suite["export"] module

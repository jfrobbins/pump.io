# idmaker.js
#
# Generator for unique IDs
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
uuid = require("node-uuid")
IDMaker = makeID: ->
  buf = new Buffer(16)
  uuid.v4 {}, buf
  id = buf.toString("base64")
  
  # XXX: optimize me
  id = id.replace(/\+/g, "-")
  id = id.replace(/\//g, "_")
  id = id.replace(RegExp("=", "g"), "")
  id

exports.IDMaker = IDMaker

# routes/clientreg.js
#
# Handle client registration
#
# Copyright 2011-2012, E14N https://e14n.com/
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
Step = require("step")
validator = require("validator")
check = validator.check
dialback = require("../lib/dialback")
maybeDialback = dialback.maybeDialback
Client = require("../lib/model/client").Client
HTTPError = require("../lib/httperror").HTTPError
addRoutes = (app) ->
  
  # Client registration
  app.post "/api/client/register", maybeDialback, clientReg
  return

clientReg = (req, res, next) ->
  params = req.body
  props = {}
  type = undefined
  unless _(params).has("type")
    next new HTTPError("No registration type provided", 400)
    return
  type = params.type
  if _(params).has("client_id")
    if type isnt "client_update"
      
      # XXX: log this
      next new HTTPError("Only set client_id for update.", 400)
      return
    props.consumer_key = params.client_id
  if _(params).has("access_token")
    next new HTTPError("access_token not needed for registration.", 400)
    return
  if _(params).has("client_secret")
    if type isnt "client_update"
      
      # XXX: log this
      next new HTTPError("Only set client_secret for update.", 400)
      return
    props.secret = params.client_secret
  if _(params).has("contacts")
    unless _.isString(params.contacts)
      next new HTTPError("contacts must be a string of space-separated email addresses.", 400)
      return
    props.contacts = params.contacts.split(" ")
    unless props.contacts.every((contact) ->
      try
        check(contact).isEmail()
        return true
      catch err
        return false
      return
    )
      next new HTTPError("contacts must be space-separate email addresses.", 400)
      return
  if _(params).has("application_type")
    if params.application_type isnt "web" and params.application_type isnt "native"
      next new HTTPError("Unknown application_type.", 400)
      return
    props.type = params.application_type
  else
    props.type = null
  props.title = params.application_name  if _(params).has("application_name")
  if _(params).has("logo_url")
    try
      check(params.logo_url).isUrl()
      props.logo_url = params.logo_url
    catch e
      next new HTTPError("Invalid logo_url.", 400)
      return
  if _(params).has("redirect_uris")
    props.redirect_uris = params.redirect_uris.split(" ")
    unless props.redirect_uris.every((uri) ->
      try
        check(uri).isUrl()
        return true
      catch err
        return false
      return
    )
      next new HTTPError("redirect_uris must be space-separated URLs.", 400)
      return
    if props.redirect_uris.length is 1
      
      # Does it look like glopped-together URLs?
      matches = props.redirect_uris[0].match(/https?:/g)
      if matches.length > 1
        next new HTTPError("redirect_uris must be space-separated URLs.", 400)
        return
  if req.remoteHost
    props.host = req.remoteHost
  else props.webfinger = req.remoteUser  if req.remoteUser
  if type is "client_associate"
    Client.create props, (err, client) ->
      if err
        next err
      else
        res.json
          client_id: client.consumer_key
          client_secret: client.secret
          expires_at: 0

      return

  else if type is "client_update"
    Client.get props.consumer_key, (err, client) ->
      if err
        next err
      else if client.secret isnt props.secret
        
        # XXX: log this
        next new HTTPError("Unauthorized", 403)
      else
        client.update props, (err, client) ->
          if err
            next err
          else
            res.json
              client_id: client.consumer_key
              client_secret: client.secret
              expires_at: 0

          return

      return

  else
    next new HTTPError("Invalid registration type", 400)
    return
  return

exports.addRoutes = addRoutes

###
Copyright (c) 2013 Nathan Wittstock

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###


MongoClient = (require 'mongodb').MongoClient
Notifier = require '../base/notifier.coffee'

module.exports =
  class MongoDB extends Notifier
    constructor: (@config, @com) ->
      @initNotifier(config, com)

      @db = null
      @collection = null
      @unpostedMessages = []
      MongoClient.connect @config.options.url, @connected

      @com.on 'message_received', (message) =>
        @messageReceived message

    connected: (err, db) =>
      if !err
        if process.env.DEBUG then console.log "MongoDB: Successfully connected to service."
        @db = db
        @db.collection @config.options.collection, @collectionCreated
      else
        if process.env.DEBUG then console.log "MongoDB: Failed to connect to Service"
        @error "error", "Failed to connect to Service", err
        @db = null
        # if we failed, try again in 1 minute
        setTimeout (=>
          MongoClient.connect @config.options.url, @connected
        ), 60000

    collectionCreated: (err, collection) =>
      if !err
        if process.env.DEBUG then console.log "MongoDB: Successfully got the collection."
        @collection = collection
        # now post any unposted messages
        for message in @unpostedMessages
          @logMessage message
        @unpostedMessages = []
      # otherwise, there was an error
      else
        if process.env.DEBUG then console.log "MongoDB: Failed to get Collection"
        @error "error", "Failed to get Collection", err
        @collection = null
        @db.close (err, result) =>
          @db = null
          if process.env.DEBUG then console.log "MongoDB: Closed connection after errors"
          if err then @error "error", "Failed to close connection to service", err
          setTimeout (=>
            MongoClient.connect @config.options.url, @connected
          ), 60000

    messageReceived: (message) =>
      if process.env.DEBUG then console.log "MongoDB: called to notify"

      if message.message_type == 'event'
        if process.env.DEBUG then console.log "MongoDB: Got event message."
        # get severity of message if armed or disarmed
        message_severity = message.data.severity.disarmed
        alert_threshold = @config.notification.disarmed
        if @com.armed
          message_severity = message.data.severity.armed
          alert_threshold = @config.notification.armed

        # if the message isn't important enough, don't send
        if message_severity < alert_threshold
          return 0

        # otherwise, send the message
        @logMessage message

      else if message.message_type == 'error'
        # always log errors
        @logMessage message

    logMessage: (message) =>
      if process.env.DEBUG
        console.log "MongoDB: Logging Message"
        console.log message
      if @collection
        if process.env.DEBUG then console.log "MongoDB: Collection exists, trying to insert."
        @collection.insert message, {w: 1}, (err, result) =>
          if err
            if process.env.DEBUG then console.log "MongoDB: Failed to log message."
            @error "error", "Failed to log message.", err
            @unpostedMessages.push message
            # close mongo connection and try again
            @collection = null
            @db.close (err, result) =>
              if process.env.DEBUG then console.log "MongoDB: Closed connection after error posting"
              if err then @error "error", "Failed to close database connection", err
              @db = null
              setTimeout (=>
                MongoClient.connect @config.options.url, @connected
              ), 60000
          else
            if process.env.DEBUG
              console.log "MongoDB: logged message"
              console.log result
      else
        if process.env.DEBUG then console.log "MongoDB: No collection was set, couldn't log message."
        # if we don't have a collection, log the unposted message for later storage
        # but we don't want to have too many if there was some sort of problem
        if @unpostedMessages.length > 100
          if process.env.DEBUG then console.log "MongoDB: Blanking Message queue."
          @unpostedMesagges = []

        if process.env.DEBUG then console.log "MongoDB: Adding message to unposted queue"
        @unpostedMessages.push message


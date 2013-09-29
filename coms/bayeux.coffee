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


faye = require 'faye'
events = require 'events'

module.exports =
  class Bayeux extends events.EventEmitter
    # Bayeux is the standard communication module, which uses `faye` as its 
    # pubsub backend.
    #
    # config - The configuration object
    constructor: (@config) ->
      if !@config.bayeux
        console.log 'Bayeux: no configuration information was present.'
        process.exit(1)

      bayeux_config = {}
      bayeux_config.mount = config.bayeux.mount || '/'
      bayeux_config.port = config.bayeux.port || 8000
      bayeux_config.timeout = config.bayeux.timeout || 45

      @bayeux = new faye.NodeAdapter(@config)
      @bayeux.listen(@port)
      @bayeux.bind 'publish', @message_received
      if process.env.DEBUG then console.log 'Bayeux: running'

      # The coms object provides the global armed/disarmed switch
      @armed = false


    # Public: Sends a message to the pubsub process.
    #
    # channel - A string representing the channel data should be sent to.
    # data - An object containing the data to be sent
    #
    # Returns nothing
    send_message: (channel, data) =>
      @bayeux.getClient().publish channel, data
      if process.env.DEBUG then console.log 'Bayeux: message published'


    # Public: Gets the Armed/Disarmed status.
    #
    # Returns a boolean representing "armed" status.
    get_status: =>
      return @armed

    
    # Private: Called by the pubsub process whenever a message is received. 
    # Responsible for emitting the events that all other local modules will 
    # act upon.
    #
    # clientId - The identifier of the sending client. For possible future use.
    # channel - A string representing the channel the message came from.
    # data - An object containing the message data.
    #
    # Returns nothing
    # Emits the 'message_received' event whenver the pubsub process receives a 
    # message.
    message_received: (clientId, channel, data) =>
      data.channel = channel
      @emit 'message_received', data
      
      # see if we got an arm/disarm message
      if data.data.command? and data.data.command in ['arm', 'disarm', 'shutdown']
        @processCriticalMessage(data)

      if process.env.DEBUG then console.log 'Bayeux: message received'


    # Private: The coms module handles critical incoming messages. This will be 
    # called whenever a message is received who's command is a magic value.
    #
    # message - The received message
    #
    # Returns nothing
    processCriticalMessage: (message) =>
      if message.data.command == 'shutdown'
        console.log "Bayeux: shutdown requested"
        # process.exit()

      @armed = if message.data.command == 'disarm' then false else true
      status = if @armed then "Armed" else "Disarmed"
      if process.env.DEBUG then console.log "System is " + status

      message_to_publish =
        app: "paper"
        source_module: "coms/bayeux"
        message_type: "event"
        date: (new Date).toISOString()
        data:
          name: @config.name
          friendly_name: @config.friendlyName
          severity:
            armed: 10
            disarmed: 10
          status: status
          message: "System is " + status
      @send_message '/control/global', message_to_publish


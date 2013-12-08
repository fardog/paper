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


twilio = require 'twilio'
url = require 'url'

module.exports =
  class Twilio
    sendMessage: (message, recipients, force) =>
      if process.env.DEBUG then console.log "Twilio: sending notification."

      # for each phone number in our recipient list, send a notification
      for phone_number in recipients
        if phone_number in @silencedRecipients and !(force?)
          if process.env.DEBUG then console.log "Twilio: ignoring silenced " + phone_number
        else
          text_message =
            body: "[paper] " + message
            to: phone_number
            from: @config.options.number

          @twilio.sms.messages.create text_message, (err, sent_message) ->
            if err?
              console.log 'Twilio: Error sending alert message.'
              console.log err
            else
              console.log 'Twilio: Message sent: ' + sent_message.sid


    processMessage: (message) =>
      if process.env.DEBUG then console.log "Twilio: processing message."

      switch message.message_type
        when 'event'
          if process.env.DEBUG then console.log "Twilio: Got Event message"
          @processEvent message
        when 'status'
          if process.env.DEBUG then console.log "Twilio: Got Status message"
          @processStatus message
        when 'control'
          if process.env.DEBUG then console.log "Twilio: Got control message"
          @processControl message
        else
          if process.env.DEBUG then console.log "Twilio: No handler for message"

    processEvent: (message) =>
      # get severity of message if armed or disarmed
      message_severity = message.data.severity.disarmed
      alert_threshold = @config.notification.disarmed
      if @com.armed
        message_severity = message.data.severity.armed
        alert_threshold = @config.notification.armed

      # if the message isn't important enough, don't send
      if message_severity < alert_threshold
        return 0

      # if we have a recipient list, we need to make sure it's intended for us
      if message.data.to? and (url.parse message.data.to).protocol == 'tel:'
        if process.env.DEBUG then console.log "Twilio: Got message to send to " + message.data.to
        @sendMessage message.data.message, [decodeURIComponent((url.parse message.data.to).path)], true
      # otherwise, send the message, but only if the "to" wasn't defined, don't 
      # force since this wasn't implicitly intended for anyone
      else if !(message.data.to?)
        if process.env.DEBUG then console.log "Twilio: Got message to send to all"
        @sendMessage message.data.message, @config.options.recipients
      else
        if process.env.DEBUG then console.log "Twilio: Got message but it wasn't intended for text"


    processStatus: (message) =>
      # if it's a status message, send it no matter what, but only to the 
      # requesting person. if the requester isn't a telephone number, ignore
      if (url.parse message.data.to).protocol == 'tel:'
        if process.env.DEBUG then console.log "Twilio: Processing Status message"
        recipient = decodeURIComponent((url.parse message.data.to).path)
        status_string = ""
        for module_name, status of message.data.status
          status_string = status_string + module_name + ":" + status + " "

        if recipient in @silencedRecipients
          status_string += "SILENCED"

        message.data.message = status_string
        @sendMessage message.data.message, [recipient], true

    processControl: (message) =>
      # if it's from a telephone number, it's intended for us
      if (url.parse message.data.from).protocol == 'tel:'
        if process.env.DEBUG then console.log "Twilio: Processing Control message"
        switch message.data.command
          when 'silence'
            if process.env.DEBUG then console.log "Twilio: silence from " + message.data.from
            @silenceRecipient decodeURIComponent((url.parse message.data.from).path)

    silenceRecipient: (number) =>
      if number in @silencedRecipients
        index = @silencedRecipients.indexOf(number)
        if index > -1
          if process.env.DEBUG then console.log "Twilio: unsilencing number " + number
          @silencedRecipients.splice(index, 1)
          @sendMessage "Unsilenced", [number], true
      else
        if process.env.DEBUG then console.log "Twilio: silencing number " + number
        @silencedRecipients.push(number)
        @sendMessage "Silenced", [number], true
      
    constructor: (config, @com) ->
      @config = config
      @twilio = new twilio(config.options.accountSid, config.options.authToken)
      @silencedRecipients = []

      @com.on 'message_received', (message) =>
        @processMessage message


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

module.exports =
  class Twilio
    send_message: (message) =>
      if process.env.DEBUG then console.log "Twilio: sending notification."

      # for each phone number in our recipient list, send a notification
      for phone_number in @config.options.recipients
        text_message =
          body: "[paper] " + message.data.message
          to: phone_number
          from: @config.options.number

        @twilio.sms.messages.create text_message, (err, sent_message) ->
          if err?
            console.log 'Twilio: Error sending alert message.'
            console.log err
          else
            console.log 'Twilio: Message sent: ' + sent_message.sid


    notify: (message) =>
      if process.env.DEBUG then console.log "Twilio: called to notify."

      # if it's an event, see if it's imporant enough to send
      if message.message_type == 'event'
        if process.env.DEBUG then console.log "Twilio: Got Event message"
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
        @send_message message

      # if it's a status message, send it no matter what
      if message.message_type == 'status'
        if process.env.DEBUG then console.log "Twilio: Got Status message"
        status_string = ""
        for module_name, status of message.data
          status_string = status_string + module_name + ":" + status + " "

        message.data.message = status_string
        @send_message message


      
    constructor: (config, @com) ->
      @config = config
      @twilio = new twilio(config.options.accountSid, config.options.authToken)

      @com.on 'message_received', (message) =>
        @notify message


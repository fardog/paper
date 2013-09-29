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


piface = require './piface'

module.exports =
  class Switch
    pin_value_changed: =>
      # read the pin's current value
      current_value = @p.read(@config.pin)

      # if it was our value that changed
      if current_value != @status
        @status = current_value

        # build a message and send it
        message =
          app: "paper"
          source_module: "sensors/pif_switch"
          message_type: "event"
          date: (new Date).toISOString()
          data:
            name: @config.name
            friendly_name: @config.friendlyName
            severity:
              armed: @config.notification.armed
              disarmed: @config.notification.disarmed
            status: @config.switch.status[current_value]
            message: @config.switch.messages[current_value]

        @com.send_message @config.channel, message

    read: =>
      @status = @p.read(@config.pin)

    get_status: =>
      @config.switch.status[@status]

    constructor: (config, @com) ->
      @config = config
      @config.pin = config.options.input

      @p = piface.PiFace
      @p.startReader()
      @status = undefined
      @p.on 'pinValuesChanged', =>
        @pin_value_changed()
        

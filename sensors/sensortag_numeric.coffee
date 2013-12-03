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


sensortag = require './sensortag'

module.exports =
  class Numeric
    numericValueChanged: (values) =>
      currentValue = values

      if currentValue != @status
        @status = currentValue

        # build a message and send it
        message =
          app: "paper"
          source_module: "sensors/sensortag_numeric"
          message_type: "event"
          date: (new Date).toISOString()
          data:
            name: @config.name
            friendly_Name: @config.friendlyName
            severity:
              armed: @config.notification.armed
              disarmed: @config.notification.disarmed
            status: @status[1]
            message: "Temperature: " + Math.round(@status[0]) + ", Humidity: " + Math.round(@status[1])

        @com.send_message @config.channel, message

    sensorTagReady: =>
      if process.env.DEBUG then console.log 'SensorTag Numeric: Got Ready, Enabling'
      @s.enable @config.sensor

    get_status: =>
      if !@status
        return "Not Read"
      Math.round(@status[1])

    constructor: (config, @com) ->
      @config = config
      @config.sensor = config.options.sensor

      @s = sensortag.SensorTag
      if process.env.DEBUG then console.log 'SensorTag Numeric: Waiting'
      @status = undefined
      if !@s.ready
        @s.on 'ready', @sensorTagReady
      else
        @sensorTagReady()
      @s.on @config.sensor + 'Changed', @numericValueChanged


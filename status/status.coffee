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

module.exports =
  class Status
    collect_status: (requestMessage) =>
      status = {}
      status["armed"] = if @com.get_status() then "yes" else "no"
      for sensor in @sensors
        status[sensor.config.name] = sensor.get_status()

      message =
        app: "paper"
        source_module: "status/status"
        message_type: "status"
        date: (new Date).toISOString()
        data:
          to: requestMessage.data.from
          status: status

      @com.send_message '/control/global', message


    constructor: (@config, @com, @sensors) ->
      @com.on 'message_received', (message) =>
        if message.data.command? and message.data.command == 'status'
          if process.env.DEBUG then console.log "Status: collecting status"
          @collect_status message



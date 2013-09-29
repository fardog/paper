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

events = require 'events'
aws = require 'aws-sdk'

module.exports =
  class TwilioSQS extends events.EventEmitter
    validateAndParseCommand: (command) =>
      command = command.replace ']', ''
      parts = command.split '['
      command = parts[0].trim().toLowerCase()
      from = parts[parts.length-1].trim()

      if from in @config.options.authorizedSenders
        if process.env.DEBUG then console.log "TwilioSQS: Valid command."
        value =
          command: command
          from: from
        return value
      else
        return null


    processDeletedMessage: (err, data) =>
      if err?
        console.log "TwilioSQS: Message couldn't be deleted."
        console.log err

    processMessage: (err, data) =>
      if err?
        console.log "TwilioSQS: There was an error getting messages."
        console.log err
      else if data.Messages?
        for message in data.Messages
          if process.env.DEBUG then console.log "TwilioSQS: Got Message"
          
          # immediately delete the message from SQS
          parameters =
            QueueUrl: @config.options.aws_endpoint
            ReceiptHandle: message.ReceiptHandle
          @sqs.deleteMessage parameters, @processDeletedMessage

          # see if the message is from a valid sender
          message_data = @validateAndParseCommand message.Body
          if message_data
            # send it to our command queue
            message_output =
              app: "paper"
              source_module: "controllers/twilio-sqs"
              message_type: "control"
              date: (new Date).toISOString()
              data:
                name: @config.name
                friendly_name: @config.friendlyName
                from: message_data.from
                command: message_data.command

            @com.send_message @control_channel, message_output

      # try to get the next message, if any
      @receiveMessage()

    receiveMessage: =>
      parameters =
        QueueUrl: @config.options.aws_endpoint
        WaitTimeSeconds: 20

      if process.env.DEBUG then console.log "TwilioSQS: getting messages."
      @sqs.receiveMessage parameters, @processMessage

    constructor: (@config, @com, @control_channel) ->
      sqs_config =
        apiVersion: @config.options.aws_apiVersion
        accessKeyId: @config.options.aws_accessKeyId
        secretAccessKey: @config.options.aws_secretAccessKey
        endpoint: @config.options.aws_endpoint
        region: @config.options.aws_region

      @sqs = new aws.SQS sqs_config
      @receiveMessage()


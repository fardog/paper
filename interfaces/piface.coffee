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


pif = require 'caf_piface'
p = new pif.PiFace()
p.init()

events = require 'events'


CURRENT_READ_VALUE = undefined
READ_INTERVAL_TIMER = null

reader = (emitter) ->
  new_read_value = p.read()
  if (new_read_value != CURRENT_READ_VALUE)
    CURRENT_READ_VALUE = new_read_value
    emitter.emit 'pinValuesChanged', CURRENT_READ_VALUE

# readResult will map the current read value to a pin
readResult = (current, pin) ->
  s = current.toString(2)  # creates binary string from current value
  while s.length < 4  # pad string at front until there are 4 characters
    s = '0' + s
  s = s.split("").reverse().join("")  # reverses characters in string
  s[pin]  # return value at pin's place

class PiFace extends events.EventEmitter
  read: (pin) ->
    readResult(CURRENT_READ_VALUE, pin)

  startReader: =>
    if !READ_INTERVAL_TIMER
      if process.env.DEBUG then console.log 'PiFace: Reader started'
      READ_INTERVAL_TIMER = setInterval (=>
        reader(@)
      ), 200

  stopReader: ->
    if READ_INTERVAL_TIMER
      clearInterval READ_INTERVAL_TIMER
      READ_INTERVAL_TIMER = null

pif_module = new PiFace()

module.exports =
  PiFace: pif_module


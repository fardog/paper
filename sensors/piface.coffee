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


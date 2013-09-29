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


# Read configuration
config = require 'nconf'
config.argv().env().file('./config.json')


# Get our global config up and running, and our pubsub processes
coms = require './' + config.get 'global:communication:adapter' || 'coms/bayeux'
com = new coms config.get 'global:communication'

# load our controllers
controllers = []
for cname, c of config.get 'controllers'
  controller = require './' + c.spec
  controllers.push (new controller c, com, config.get 'global:communication:controlChannel')

# load our notifiers
notifiers = []
for nname, n of config.get 'notifiers'
  notifier = require './' + n.spec
  notifiers.push (new notifier n, com)

# load our sensors
sensors = []
for sname, s of config.get 'sensors'
  sensor = require './' + s.spec
  sensors.push (new sensor(s, com))

# load our status module
stat = require './' + config.get 'global:status:adapter' || 'status/status'
status = new stat (config.get 'global:status'), com, sensors


# Start a REPL if we're in debug
if process.env.DEBUG
  nesh = require 'nesh'
  opts =
    welcome: 'paper debug mode.',
    prompt: 'paper> '

  nesh.config.load()
  nesh.loadLanguage 'coffee'
  nesh.start opts, (err) ->
    if (err)
      nesh.log.error(err)


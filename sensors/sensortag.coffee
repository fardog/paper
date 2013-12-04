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


sensortag = require 'sensortag'
events = require 'events'

class SensorTag extends events.EventEmitter
  constructor: () ->
    @tag = null
    @deviceName = null
    @serialNumber = null
    @systemId = null
    @services = []
    @reader = null
    @readInterval = 120000
    @discover()

  readSensors: =>
    if process.env.DEBUG then console.log 'SensorTag: Reading'
    for service in @services
      switch service.type
        when 'humidity'
          @tag.readHumidity (temperature, humidity) =>
            service.value = [temperature, humidity]
            @emit service.emit, service.value

        when 'irTemperature'
          @tag.readIrTemperature (objectTemperature, ambientTemperature) =>
            service.value = [objectTemperature, ambientTemperature]
            @emit service.emit, service.value

        when 'barometricPressure'
          @tag.readBarometricPressure (pressure) =>
            service.value = [pressure]
            @emit service.emit, service.value

        when 'accelerometer'
          @tag.readAccelerometer (x, y, z) =>
            service.value = [x, y, z]
            @emit service.emit, service.value

        when 'magnetometer'
          @tag.readMagnetometer (x, y, z) =>
            service.value = [x, y, z]
            @emit service.emit, service.value

        when 'gyroscope'
          @tag.readGyroscope (x, y, z) =>
            service.value = [x, y, z]
            @emit service.emit, service.value

  servicesDiscovered: =>
    if process.env.DEBUG then console.log 'SensorTag: Services Discovered'
    @ready = true
    @emit 'ready', true
    @tag.readDeviceName (deviceName) =>
      @deviceName = deviceName
    @tag.readSerialNumber (serialNumber) =>
      @serialNumber = serialNumber
    @tag.readSystemId (systemId) =>
      @systemId = systemId
    @reader = setInterval =>
      @readSensors()
    , @readInterval

  connected: =>
    if process.env.DEBUG then console.log 'SensorTag: Connected'
    @tag.discoverServicesAndCharacteristics @servicesDiscovered

  discovered: =>
    if process.env.DEBUG then console.log 'SensorTag: Discovered'
    @tag.connect @connected

  discover: =>
    if process.env.DEBUG then console.log 'SensorTag: Discovering'
    sensortag.discover (sensorTag) =>
      @tag = sensorTag
      @discovered()

  enable: (sensorName) =>
    if process.env.DEBUG then console.log 'SensorTag: Enabling ' + sensorName
    switch sensorName
      when 'humidity'
        @tag.enableHumidity =>
          if process.env.DEBUG then console.log 'SensorTag: Humidity Enabled'
          @services.push data =
            type: 'humidity'
            value: null
            emit: 'humidityChanged'
          @readSensors()

      when 'irTemperature'
        @tag.enableIrTemperature =>
          if process.env.DEBUG then console.log 'SensorTag: IR Temperature Enabled'
          @services.push data =
            type: 'irTemperature'
            value: null
            emit: 'irTemperatureChanged'
          @readSensors()

      when 'barometricPressure'
        @tag.enableBarometricPressure =>
          if process.env.DEBUG then console.log 'SensorTag: Barometric Pressure Enabled'
          @services.push data =
            type: 'barometricPressure'
            value: null
            emit: 'barometricPressureChanged'
          @readSensors()

      when 'accelerometer'
        @tag.enableAccelerometer =>
          if process.env.DEBUG then console.log 'SensorTag: Accelerometer Enabled'
          @services.push data =
            type: 'accelerometer'
            value: null
            emit: 'accelerometerChanged'
          @readSensors()

      when 'magnetometer'
        @tag.enableMagnetometer =>
          if process.env.DEBUG then console.log 'SensorTag: Magnetometer Enabled'
          @services.push data =
            type: 'magnetometer'
            value: null
            emit: 'magnetometerChanged'
          @readSensors()

      when 'gyroscope'
        @tag.enableGyroscope =>
          if process.env.DEBUG then console.log 'SensorTag: Gyroscope Enabled'
          @services.push data =
            type: 'gyroscope'
            value: null
            emit: 'gyroscopeChanged'
          @readSensors()


  read: (service) =>
    if process.env.DEBUG then console.log 'SensorTag: Reading'
    @services[service].status

if process.env.DEBUG then console.log 'SensorTag: Starting'

sensorTag = new SensorTag()

module.exports =
  SensorTag: sensorTag


paper
=====

![Image of Paper, the dog](https://raw.github.com/fardog/paper/master/docs/assets/images/paper.jpg "Paper, a dog.")

Paper is a home security/monitoring system, written modularly and able to 
support a variety of sensor types, notification systems, and controllers. That 
is the goal, at least; right now it's very basic, and shouldn't be considered 
anything more than a technology demo.

Hopefully as this is cleaned up and better assembled it will be useful for 
others, and writing and including modules will be simpler. For now, the 
modularity is not package based, but is just file based within this repository.

The current version was written to run on a Raspberry Pi running the latest 
Raspbian and Node.js v0.10.x, using a PiFace Digital for its sensors.

"Paper" is my adorable dog, for whom this project is named.

Architecture
------------

Paper is designed to work around a pubsub backend—currently, 
[Faye](https://npmjs.org/package/faye)—for communication with external systems 
and as an internal messaging system; however individual modules aren't aware of 
the pubsub communications, they are evented. The goal here is to create 
something that's light-weight and easy to write sensors for, but extensible to 
multiple systems.

There are a few different module categories:

- **Sensors:** Any device which reports information.
- **Notifiers:** Any device which receives information from a sensor, and acts
on it.
- **Controllers:** Any device presenting an external interface used to control 
the system's operation.
- **Status:** A special type of controller which is used to report overall 
system status.
- **Coms:** Another special type of controller, which manages the communication 
throughout the system. It's my intention to replace this with an internal 
routing system at some point, but right now it's an event emitter.

At the moment, these are implemented haphazardly, but as the architecture gets 
more stable in my head, they will inherit from a base class and implement their 
own APIs.

Once exception to the modularity of the system is armed/disarmed and "shutdown" 
commands, which are directly implemented in the "Coms" object. This is because 
no sensor or external system should need to know about this status; it's their 
job to act as necessary and report findings to the notifiers which handle 
actual reporting based on the current operational mode. The "Coms" object is a 
convenient global place to handle these special cases.

Messaging API
-------------

*paper* uses passes messages from each of it's modules using a well-defined JSON
object, in the following format:

```
{
    app: "paper",
    source_module: <module_name>,
    message_type: [event, control, status],
    date: <ISO8601_string>,
    channel: <pubsub_channel>,
    data: {}
}
```

The `channel` key should be automatically inserted into the object by the pubsub
receiver. What `data` contains varies on the message type.

### Event

```
{
    app: "paper",
    source_module: <module_name>,
    message_type: "event",
    date: <ISO8601_string>,
    channel: <pubsub_channel>,
    data: {
        name: <string>,
        friendly_name: <string>,
        severity: {
            armed: <integer>,
            disarmed: <integer>
        },
        status: <string>,
        message: <string>
    }
}
```

### Command

```
{
    app: "paper",
    source_module: <module_name>,
    message_type: "control",
    date: <ISO8601_string>,
    channel: <pubsub_channel>,
    data: {
        name: <string>,
        friendly_name: <string>,
        from: <phone_number>,
        command: <command_string>
    }
}
```

### Status

```
{
    app: "paper",
    source_module: <module_name>,
    message_type: "status",
    date: <ISO8601_string>,
    channel: <pubsub_channel>,
    data: {
        sensor_name1: <status>,
        sensor_name2: <status>,
        …
    }
}

A<a href="https://codeclimate.com/repos/57d10b3aaee68e0a2d0016b7/feed"><img src="https://codeclimate.com/repos/57d10b3aaee68e0a2d0016b7/badges/aad862afb3ada6425b90/gpa.svg" /></a>
[![Dependency Status](https://gemnasium.com/badges/github.com/RubyDevInc/aws-iot-device-sdk-ruby.svg)](https://gemnasium.com/github.com/RubyDevInc/aws-iot-device-sdk-ruby)
[![Gem Version](https://badge.fury.io/rb/aws_iot_device.svg)](https://badge.fury.io/rb/aws_iot_device)

# AWS IoT Device SDK for Ruby

## Contents
* [Dependencies](#dependencies)
* [Overview](#overview)
* [Installation](#installation)
* [Usage](#usage)
  * [Getting started](#getting-started)
  * [Sample files](#sample-files)
* [API Description](#api-description)
  * [Shadow Client](#shadow-client)
  * [Connection Mode](#connection-mode)
  * [MQTT Adapter](#mqtt-adapter)
* [License](#license)
* [Contact](#contact)

## Dependencies
Ruby gems:
- ruby >= 2.2
- mqtt >= 0.0.2
- json >= 2.0
- facets >= 3.1
- timers >= 4.1
- paho-mqtt >= 0.0.2

## Overview
`aws_iot_device` is a gem that enables a remote client to communicate with the AWS IoT platform. The AWS IoT platform allows to register a device as a `thing`, each `thing` is referred by a `shadow` that stores the `thing` (device) status. The gem uses the MQTT protocol to control the `thing` registered on the AWS IoT platform. The MQTT protocol is a lightweight protocol used to exchange short messages between a client and a message broker. The message broker is located on the AWS IoT platform, and the client is provided by the `aws_iot_device` gem, the default client is the `paho-mqtt`. The `paho-mqtt` client has a MQTT API and a callback system to handle the events trigger by the mqtt packages.

## Installation
The gem is currentely in a unstable version, key features are available but any improvements is welcomed :).  
There are two ways to install the gem, from [rubygems](https://rubygems.org/gems/aws_iot_device) or directly from [sources](https://github.com/RubyDevInc/aws-iot-device-sdk-ruby).
- From RubyGems:  
The gem may be find on [RubyGems](https://rubygems.org/gems/aws_iot_device) and installed with the following command:
```
gem install aws_iot_device
```

- From sources:

The gem could be download and installed manually:

```
git clone https://github.com/RubyDevInc/aws-iot-device-sdk-ruby.git
cd aws-iot-device-sdk-ruby
bundle install
```
## Usage
### Getting started
The following example is a strait-forward way for using shadows. Check at the samples files for more detailed usage.
```ruby
require "aws_iot_device"

host = "AWS IoT endpoint"
port = 8883
thing = "Thing Name"

root_ca_path = "Path to your CA certificate"
private_key_path = "Path to your private key"
certificate_path = "Path to your certificate"

shadow_client = AwsIotDevice::MqttShadowClient::ShadowClient.new
shadow_client.configure_endpoint(host, port)
shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)
shadow_client.create_shadow_handler_with_name(thing, true)

shadow_client.connect
shadow_client.get_shadow do |message|
  # Do what you want with the get_shadow's answer
  # ...
  p ":)"
end
sleep 2 #Timer to ensure that the answer is received

shadow_client.disconnect
```

### Sample files
Once you have cloned that repository the several samples files provide test on the API a multiple levels.
The shadow examples could be run with the following command :
```
ruby samples/shadow_client_samples/samples_shadow_client_xxx.rb -c "CERTIFICATE PATH" -k "PRIVATE KEY PATH"  -a "CA CERTIFICATE PATH" -H "AWS IOT ENDPOINT" -t "THING NAME"
```

## API Description
Thank you very much for your interst in the `aws_iot_device` gem. The following part details all the features available with this gem.
### Shadow Client
The shadow client API provide the key functions which are needed to control a thing/shadow on the Aws IoT platform. The methods contains in the API could be seperate in three differents roles, the configuration roles, the communication roles, and the treatements roles.
#### Configuration role
The Shadow client initializer would create the mqtt client that the shadow client uses to communicate with the remote host. The parameters available on the initialization depend on the type of the mqtt client. The default mqtt client type is the paho_client, the available parameter are detailed in `paho-mqtt` gem [page](https://github.com/RubyDevInc/paho.mqtt.ruby#initialization).

The remote host(endpoint) and port could be configured with the following method:
```
shaadow_client.configure_endpoint(host, port)
```

The encryption configuration could be done with the following method:
```
shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)
```

The thing where the client would connect is done by the following method. The persitent_subscribe attribute is a boolean that would prevent the client to unsubscribe to the mqtt topic after every action. As the susbcription require a short time, for performace issues it might usefull to keep subscribed (default is `false`).
```
shadow_client.create_shadow_handler_with_name(thing, persistent_subscribe)

```

Finally, the connect method enable to send a connect request and (re)define some attributes threw a `Hash`. The available parameter are `:host`, `:port`, `:keep_alive`, `:persitent` and `:blocking`. `:persistent` and `:blocking` are detailed in the connection mode [section](#connection-mode)
```
shadow_client.connect
```

#### Communication role
In the API there is three method that directely act on the remote shadow. `timeout` is the time until which the request should be consider as a failure. The default timeout is five second. The `get` and `delete` do not accept a payload where it is mandaory for the `update`. 
```
timeout = 2

shadow_client.get_shadow(timeout)

payload = "{\"state: \": \"desired\": ..... }"
shadow_client.update_shadow(payload)

shadow_client.delete_shadow
```

#### Callbacks
Callbacks are small piece of code that would be execute when the answer of one action is received by the client. The callbacks may be register as `block`, `proc` or `lambda`.  
The Shadow client API enables to register two kind of callbacks, one for generic action, and another one for specific action. The generic action callback would be call on every answer of the dicated action, whereas the specific action callback would be execute only on the answer to the action call which had triggered it. The followings lines provide an examples of the callbacks usage.
```ruby
# Register a callback for the get action as a block
shadow_client.register_get_callback do
  puts "generic callback for get action"
end

# Register a callback for the delete action as a proc
shadow_client.register_delete_callback(proc { puts "generic callback for delete action"})

# Register a callback for the update action as a lambda
shadow_client.register_update_callback(lambda {|message| puts "genereic callback for update action"})

# Register a callback for the delta events
shadow_client.register_delta_callback do
  puts "delta have been catch in a callback"
end

# Send a get request with an associated callback in a block
shadow_client.get_shadow do
  puts "get thing"
end

# Send a delete request with an associated callback in a proc
shadow_client.delete_shadow(timeout, proc {puts "delete thing"})

# Send a udpate request with an associated callback in a lambda
shadow_client.update_shadow("{\"state\":{\"desired\":{\"message\":\"Hello\"}}}", timeout, lambda {|message| puts "update thing"})

# Clear out the previously registered callback for each action
shadow_client.remove_get_callback
shadow_client.remove_update_callback
shadow_client.remove_delete_callback
shadow_client.remove_delta_callback
```

### Client persitences
For performance issues, sometimes subscriptions and (re)connection time would better to saved. This could be done with two different persistences, the subscription persistence and the connection persistence. The subscription persistence keeps the shadow_client subscribed to action topics (get/accepted, get/rejected, update/accepted, update/rejected, delete/accepted and delete/rejected). The subscription process require a short time, the persistent subscription avoid to susbscribe before each and so saved the subscription time. The subscription persistence could be set at the initialization of the shadow handler.
```ruby
shadow_client.create_shadow_handler_with_name(shadow_name, is_persistent_subscribe)
```

The connection persistence enables the client to keep the mqtt connection alive until the client explicitly requests to disconnect. The basic client would disconnect from the remote host if no activity has been detected for a prest keep_alive timer. There is two ways to configure the connection persistence, at the initialization of the shadow client or at the connection time.
```ruby
shadow_client = AwsIotDevice::ShadowClient.new({:persistent => true})
# Or
shadow_client.connect({:persitent => true})
```


### MQTT Adapter
The `aws-iot-device` gem is based on a MQTT client (`paho-mqtt`) that enables the usage of basic MQTT operations. Among this features, the most popular one is the subscription and publishing to standard MQTT topics.
```ruby
mqtt_client = AwsIoTDevice::MqttShadowClient::MqttManager.new

mqtt_client.config_endpoint(host, port)
mqtt_client.config_ssl_context(host, port)
mqtt_client.connect

mqtt_client.subscribe(topic, qos, callback)
mqtt_client.publish(topic, "Hello world!", qos, retain)

mqtt_client.unsubscribe(topic)
mqtt_client.disconnect
```
For the default paho mqtt_client, some callbacks are available for each event related with the MQTT protocol. We recommend to read the `paho-mqtt` [gem page](https://github.com/RubyDevInc/paho.mqtt.ruby#handlers-and-callbacks) for more etails about the mqtt callbacks usage.

## License
## Contact

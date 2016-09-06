# AWS IoT SDK for Ruby


## Requirements
Ruby gems:
- ruby ~> 2.2
- mqtt ~> 0.4
- json ~> 1.8
- facets ~> 3.1
- timers ~> 4.1

## Installation

The project is still a beta version and until its gem release, it should be download and installed from sources.
```
git clone https://github.com/RubyDevInc/aws-iot-device-sdk-ruby.git
```

In order to use the SDK, the `LOAD_PATH` should be updated. It could be done by adding a new path to the `RUBYLIB` variable as in the following command.
```bash
export RUBYLIB=$RUBYLIB:"...path to sdk directory.../MqttAdapters":"path to sdk directory.../MqttShadowClient"
```


## Introduction
The AWS IoT SDK for Ruby is a gems which enables to manage device registered as shadow/things on the AWS IoT platform. A shadow is a JSON document that describe the state of thing(app, device, sensor,...). The JSON document representing the state of the shadow is split in two part, the desired and the reported state of the thing. Three operations could be  done on the Shadow: 
- Get: read the current state of the shadow
- Update: add, change or remove the attribute value of the shadow
- Delete: clear all the attribute value of the shadow

The client communicates with the AWS IoT platform through the MQTT protocol. An adapter pattern is provided to allow several implementation of the mqtt client and thus make the client independent form its back-end library implementation. In the current version, the default settings are using a client based on the ruby-mqtt gems.  According to the shadow management, operations are performed by sending message on the dedicated MQTT topics. The answer could be read on the corresponding MQTT topics, then some treatment could be process thanks to a system of callback.

## Using the ShadowClient
Some example files are provided in the samples directory. They could be run by the following command.
```bash
ruby "path to sdk "/samples/"example_file".rb -c "path to certificate" -a "path to authority certificate" -k "path to key" -H "aws endpoint URI" -t "thing name"
```

### Shadow Client
The ShadowClient class handles the function that would acts on the shadow. It is way the easiest to manipulate the shadow thanks to the different methods of the API. The following example details step by step how to create a ShadowClient, connect it to a shadow and then execute some basic operations on the shadow :

```ruby
### Credentials and host information needed to connect
root_ca_path = "PATH_TO_YOUR_ROOT_CA_FILE"
private_key_path = "PATH_TO_YOUR_PRIVATE_KEY"
certificate_path = "PATH_TO_YOUR_CERTIFICATE_FILE"

# For exemple for Tokyo area:  host = "xxx.iot.ap-northeast-1.amazonaws.com"
host = "ENDPOINT_URI_ON_AWS"

port = 8883 #default port of MQTT protocol
time_out = 5

### Create and set up a ShadowClient

my_shadow_client = AwsIot::MqttShadowClient::ShadowClient.new
my_shadow_client.configure_endpoint(host, port)
my_shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)

### Conect the ShadoaClient and attach it to existing thing 
my_shadow_client.connect
my_shadow_client.create_shadow_handler_with_name("YOUR_THING_NAME", false)

callback = Proc.new do |message|
    puts "Special callback for the topic #{message.topic}"
end
### The  three basic AWS Iot operation:
### time_out is a integer reprensenting the time to keep request alive in second
my_shadow_client.get_shadow(callback, time_out)
# or without special callback 
my_shadow_client.get_shadow(nil, time_out)

my_shadow_client.delete_shadow(callback, time_out)

### Update need a formated payload:
payload = '{ "state":{ "desired":{ "attr1":"foo" }}}' 
my_shadow_client.update_shadow(payload, callback, time_out)
```


### Shadows Topics
The TopicManager class handles the subscribing and plublishing operations for a shadow. Its functions are used by the ShadowClient class during the get, update and delete operations but they also may be called directely.  Publish and Subscribe requests are sent on the reserved MQTT topics of the selected shadow. For each operation, those topics have a similar structure:
```
$aws/things/"SHADOW_NAME"/shadow/"ACTION_NAME"
```
Depending on the acceptation of the request, the answer would be received either on the accepted or rejected MQTT topics:
```
$aws/things/"SHADOW_NAME"/shadow/"ACTION_NAME"/accepted
$aws/things/"SHADOW_NAME"/shadow/"ACTION_NAME"/rejected
```
Another topic is reserved only for some answer of the update action, the delta topic. If the desired attributes and the reported attributes have differents values in the JSON file describing the shadow state, a message would be send on the delta to report those differences. 
```
$aws/things/"SHADOW_NAME"/shadow/update/delta"
```
The TopicManager class implements the function to publish and subscribed to those reserved topic
```ruby
root_ca_path = "PATH_TO_YOUR_ROOT_CA_FILE"
private_key_path = "PATH_TO_YOUR_PRIVATE_KEY"
certificate_path = "PATH_TO_YOUR_CERTIFICATE_FILE"
ssl = true

# For exemple for Tokyo area:  host = "xxx.iot.ap-northeast-1.amazonaws.com"
host = "ENDPOINT_URI_ON_AWS"
port = 8883 #default port of MQTT protocol

mqtt_manager = AwsIot::MqttShadowClient::MqttManager.new(host,
                             port,
                             ssl,
                             certificate_path,
                             private_key_path,
                             root_ca_path)

mqtt_manager.connect

manager = AwsIot::MqttShadowClient::TopicManager.new(mqtt_manager)

### ACTION_NAME among "get", "update", "delete"
manager.shadow_topic_publish(shadow_name, shadow_action, payload)

### ACTION_NAME among "get", "update", "delete" or "delta"
### callback is a Proc that would be executed when message is received on the subscribed topic (default is nil) 
manager.shadow_topic_subscribe("SHADOW_NAME", "SHADOW_ACTION", callback=nil)
manager.shadow_topic_unsubscribe(shadow_name, shadow_action)
```

### Shadow Action Manager
The ShadowActionManager enable to the client to perform the basic action on the shadow, and then execute a default callback with the answer. A callback defined be the user and send as parameter with the action may also been executed. For each operation a task counter is set to hold the number of task which are waiting answer. The ShadowActionManager class could be initialized with two mode, persistent and not-persistent.  In the not-persistent case, the client will automatically unsubscribe to action topic when its corresponding task counter go back to 0. The persistent mode will keep the client subscribed to the topic even if the task counter is 0. In the current version, subscribe to a topic require 2 second to assert the subscription is completed.  The persistent mode enable to run that waiting timer only one for each operation(for the first one).
```ruby
### Directly create the ShadowManagerAction
### SUBSRIBE_MODE is a boolean, 'true'  for persistent mode and (default)'false'  for not-persistent 
client = AwsIot::MqttShadowClient::ShadowActionManager.new("THING_NAME", "TOPIC_MANGER", "SUBSCRIBE_MODE")

### Or through a ShadowClient  object
my_shadow_client = AwsIot::MqttShadowClient::ShadowClient.new
client = my_shadow_client.create_shadow_handler_with_name("THING_NAME", "SUBSCRIBE_MODE")

### The three basic action: 
client.shadow_get("YOUR_CALLBACK_OR_NIL", "TIME_OUT")#TIME_OUT is a integer reprensenting the time to keep request alive in second
client.shadow_update("UPDATE_PAYLOAD", "YOUR_CALLBACK_OR_NIL", "TIME_OUT")
client.shadow_delete("YOUR_CALLBACK_OR_NIL", "TIME_OUT")
```
## The MQTT Manager
The MQTTManager class support the operation related with the mqtt protocol, it is a customized MQTT client. According to the MQTT protocol, the MQTTManager may connect, publish, subscribe and disconnect. It holds a callbacks system which  are triggered by mqtt event, for exemple  when a message is received on a subscribed topic. Currently (September 2016), the callback system only support the message(PUBLISH) event, other events (CONNACK, SUBACK, ...) should be supported in the future version.  It is possible to perform the previous AWS Iot operation through the MQTTManager,  by  simply typing the desired topics in the publish request. The following example detailed how to sent a AWS Iot get request at the MQTT level.
```ruby
### There two way to initiate the object :
# 1) Send parameter when creating the object and connect
client = AwsIot::MqttShadowClient::MqttManager.new(host: "YOUR_AWS_ENDPOINT",
                             port: 8883,
                             ssl: true,
                             cert_file: "YOUR_CERT_FILE_PATH",
                             key_file: "YOUR_KEY_FILE_PATH",
                             ca_file: "YOUR_ROOT_CA_FILE_PATH")

# 2) A step by step initialization
client = AwsIot::MqttShadowClient::MqttManager.new()
client.host =  "YOUR_AWS_ENDPOINT"
client.ssl = true
client.port = 8883
client.cert_file = "YOUR_CERT_FILE_PATH"
client.key_file = "YOUR_KEY_FILE_PATH"
client.ca_file = "YOUR_ROOT_CA_FILE_PATH"

### Then send a mqtt connect request
client.connect()

client.subscribe("THING_TOPIC_GET_ACCEPTED")
sleep  2 # Assert the subscription is completed
### An example of AWS Iot get operation
client.publish("THING_TOPIC_GET",  "")
sleep  2 # Assert the answer is received to execute the callback
client.unsubscribe("THING_TOPIC_GET_ACCEPTED")

client.disconnect()
``` 

## MQTT Adapters modules
The previously detailed MQTTManager class is said to be based on a MQTT client, in this project the MQTT client is implemented as an adapters design pattern named the MQTTAdapter.  The adapter design pattern enables the client implementation to be independent from the back-end MQTT library. Thanks to this design pattern, the MQTTAdapter can work over several implementations of the MQTT protocol. The default implementation used in the project is the [ruby-mqtt](https://github.com/njh/ruby-mqtt) module, where some new features have been added. The adapters defined the method that should be accessible to higher level classes (ex. MQTTManager). 

### Ruby MQTT Adapter
The [ruby-mqtt](https://github.com/njh/ruby-mqtt) gem provides a client which does the basic MQTT operation(connect, subscribe, publish ....) by reading the packets directly from the sockets.  It adapts the method of the [ruby-mqtt](https://github.com/njh/ruby-mqtt) gem in order to match with the definition in the MQTTAdapter. Inspired by the [Paho](http://www.eclipse.org/paho/) library, a system of (infinite)loop in background is added to this class. This loop system enables a not blocking and  automated message reading.  Also, a callback system is enabled to make some treatment when message are received on a subscribed MQTT topic. If no specific callback is registered for the topic a default callback is executed.

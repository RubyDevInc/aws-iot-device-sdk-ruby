$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

client = setting_mqtt_client

client2 =  setting_mqtt_client

callback = Proc.new do |message|
  p " Client1 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

callback2 = Proc.new do |message|
  p " Client2 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

client.subscribe("topic_2", 0, callback)
client2.subscribe("topic_1", 0,callback2)

puts "# STARTING EXAMPLE #"
client.publish("topic_1", "Hello Sir. My name is client 1. How do you do? ")
client2.publish("topic_2", "Hello Mister Client 1. My name is client 2. How do you do?")
sleep 1

2.times do
  client.publish("topic_1", "How do you do?")
  sleep 1
  client2.publish("topic_2", "How do you do?")
  sleep 1
end
sleep 2
client.disconnect
client2.disconnect

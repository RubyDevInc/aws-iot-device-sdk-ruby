$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

mqtt_client = setting_mqtt_client

topic_client = setting_topic_manager(mqtt_client)

filter_callback = Proc.new do |message|
  puts "Received (through filtered callback) : "
  puts "------------------- Topic: #{message.topic}" 
  puts "------------------- Payload: #{message.payload}"
  puts "###################"
end

topic_client.shadow_topic_subscribe("get", filter_callback)

4.times do
  topic_client.shadow_topic_publish("get", "")
end

sleep 2

mqtt_client.disconnect


$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

mqtt_client = setting_mqtt_client
client = setting_action_manager(mqtt_client)

client.register_shadow_delta_callback(filter_callback)
timeout = 5

n = 1
5.times do
  json_payload = "{\"state\":{\"desired\":{\"property\":\"RubySDK\",\"count\":#{n}}}}"
  client.shadow_update(json_payload, timeout, filter_callback)
  n += 1
end

sleep timeout

mqtt_client.disconnect

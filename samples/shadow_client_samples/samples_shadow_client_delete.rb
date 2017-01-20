$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

my_shadow_client = setting_shadow

n = 1
3.times do
  puts "Start shadow_delete\n"
  my_shadow_client.delete_shadow(5, filter_callback)
  sleep 0.01
  json_payload = '{"state":{"desired":{"property":"RubySDK"}}}'
  my_shadow_client.update_shadow(json_payload, 5)
  n += 1
end

sleep 2

my_shadow_client.disconnect

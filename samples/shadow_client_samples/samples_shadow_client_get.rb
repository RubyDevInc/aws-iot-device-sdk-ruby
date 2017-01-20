$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

my_shadow_client = setting_shadow

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow(2, filter_callback)

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow do
  puts "Block callback for a token"
end

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow(2, filter_callback)

sleep 3

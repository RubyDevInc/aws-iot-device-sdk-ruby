$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

my_shadow_client = setting_shadow

my_shadow_client.connect do |client|

  puts "##### Starting test_shadow_client_get ######"
  client.get_shadow(4, filter_callback)
  
  puts "##### Starting test_shadow_client_get ######"
  client.get_shadow(4) do
    puts "CALLED FROM BLOCK"
  end
  
  puts "##### Starting test_shadow_client_get ######"
  client.get_shadow(4, filter_callback)
  sleep 5
end

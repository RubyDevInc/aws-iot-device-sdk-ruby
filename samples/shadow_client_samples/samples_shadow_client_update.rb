$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

delta_callback = Proc.new do |delta|
  message = JSON.parse(delta.payload)
  puts "Catching a new message : #{message["state"]["message"]}\n##########################################\n"
end

my_shadow_client = setting_shadow
my_shadow_client.register_delta_callback(delta_callback)

n = 1
3.times do
  puts "Type the message that you want to register in the thing:"
  entry = $stdin.readline()
  json_payload = "{\"state\":{\"desired\":{\"message\":\"#{entry.delete!("\n")}\"}}}"
  my_shadow_client.update_shadow(json_payload, 5, filter_callback)
  puts "#{3 - n} Message(s) left"
  n += 1
end

sleep 3

my_shadow_client.disconnect

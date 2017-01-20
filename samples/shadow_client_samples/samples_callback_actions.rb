$:.unshift(File.expand_path("../../../samples", __FILE__))

require 'aws_iot_device'
require 'config_shadow'

shadow_client = setting_shadow

get_callback = proc { puts "Execute the get callback"}
update_callback = proc { puts "Execute the update callback"}
delete_callback = proc { puts "Execute the delete callback"}

shadow_client.register_get_callback(get_callback)
shadow_client.register_update_callback(update_callback)
shadow_client.register_delete_callback(delete_callback)

2.times do
  shadow_client.get_shadow
  shadow_client.delete_shadow
  json_payload = "{\"state\":{\"desired\":{\"message\":\"HELLO\"}}}"
  shadow_client.update_shadow(json_payload)
end


shadow_client.get_shadow do
  puts "Execute single callback for one specific action"
end

shadow_client.get_shadow

sleep 2

shadow_client.disconnect

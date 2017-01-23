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

timeout = 4

shadow_client.connect

shadow_client.get_shadow do
  puts "get thing"
end
shadow_client.delete_shadow(timeout, proc {puts "delete thing"})
shadow_client.update_shadow("{\"state\":{\"desired\":{\"message\":\"Hello\"}}}", timeout, lambda {|message| puts "update thing"})

sleep timeout
shadow_client.disconnect

require "aws_iot_device"

host = "AWS IoT endpoint"
port = 8883
thing = "Thing Name"
root_ca_path = "Path to your CA certificate"
private_key_path = "Path to your private key"
certificate_path = "Path to your certificate"

# Create a new client with empty arguments 
shadow_client = AwsIotDevice::MqttShadowClient::ShadowClient.new

# Configure the endpoint and the port the client would connect
shadow_client.configure_endpoint(host, port)

# Configure the credentials to enable a connection over TLS/SSL encryption
shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)

# Create an event handler to bind the client with the remote thing in a persistent mode
shadow_client.create_shadow_handler_with_name(thing, true)

# Local timeout used for operation
timeout = 4

# Send a connect request to the AWS IoT platform
shadow_client.connect

# Register a callback for the get action as a block
shadow_client.register_get_callback do
  puts "generic callback for get action"
end

# Register a callback for the delete action as a proc
shadow_client.register_delete_callback(proc { puts "generic callback for delete action"})

# Register a callback for the update action as a lambda
shadow_client.register_update_callback(lambda {|_message| puts "generic callback for update action"})

# Register a callback for the delta events
shadow_client.register_delta_callback do
  puts "delta have been catch in a callback"
end

# Send a get request with an associated callback in a block
shadow_client.get_shadow do
  puts "get thing"
end

# Send a delete request with an associated callback in a proc
shadow_client.delete_shadow(timeout, proc {puts "delete thing"})

# Send a udpate request with an associated callback in a lambda
shadow_client.update_shadow("{\"state\":{\"desired\":{\"message\":\"Hello\"}}}", timeout, lambda {|_message| puts "update thing"})

# Sleep to assert all opereation have been processed
sleep timeout

# Clear out the previously registered callback for each action
shadow_client.remove_get_callback
shadow_client.remove_update_callback
shadow_client.remove_delete_callback

# Explicit disconnect from the AWS IoT platform
shadow_client.disconnect

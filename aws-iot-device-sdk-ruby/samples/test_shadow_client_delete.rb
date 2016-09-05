require "shadow_client"

root_ca_path = "/Users/Pierre/certs/root-CA.crt"
private_key_path = "/Users/Pierre/certs/private.pem.key"
certificate_path = "/Users/Pierre/certs/certificate.pem.crt"

host = "a2perapdhhaey0.iot.ap-northeast-1.amazonaws.com"
port = 8883

my_shadow_client = ShadowClient.new
my_shadow_client.configure_endpoint(host, port)
my_shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)

my_shadow_client.connect

cli = my_shadow_client.create_shadow_handler_with_name('TestThing', true)

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

n = 1

3.times do
  puts "Start shadow_delete\n"
  cli.shadow_delete(filter_callback, 5)
  json_payload = "{\"state\":{\"desired\":{\"property\":\"RubySDK\"}}}"
  cli.shadow_update(json_payload, nil, 5)
  n += 1
end
sleep 5

my_shadow_client.disconnect

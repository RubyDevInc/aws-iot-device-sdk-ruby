$LOAD_PATH << '~/IoT_raspberry_pi/MqttAdapterLib/lib'

require "mqtt_adapter_lib"

### Create client with the two different way
cli = MqttAdapterLib::MqttAdapter.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                                     port: 8883,
                                     ssl: true,
                                     cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                                     key_file: "/Users/Pierre/certs/private.pem.key",
                                     ca_file: "/Users/Pierre/certs/root-CA.crt")

cli2 = MqttAdapterLib::MqttAdapter.new
cli2.host = "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com"
cli2.port = 8883
cert_file = "/Users/Pierre/certs/certificate.pem.crt"
key_file = "/Users/Pierre/certs/private.pem.key"
ca_file = "/Users/Pierre/certs/root-CA.crt"
cli2.set_tls_ssl_context(ca_file, cert_file, key_file)

### Create two Proc that would be used as default callback for each client
p = Proc.new do |message|
  p " Client1 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

p2 = Proc.new do |message|
  p " Client2 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

### Associate the callback to the client
cli2.on_message = p2
cli.on_message = p

cli.connect
cli2.connect

cli.subscribe("topic_2")
cli2.subscribe("topic_1")

sleep 2

cli.publish("topic_1", "Hello There! It is client 1. How do you do? ")

sleep 2

cli2.publish("topic_2", "Hi! I am client 2. How do you do?")

sleep 2

cli2.disconnect
cli.disconnect

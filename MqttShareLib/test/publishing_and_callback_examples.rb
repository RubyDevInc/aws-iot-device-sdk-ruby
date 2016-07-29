$LOAD_PATH << '../lib'

require "mqtt_share_lib"


cli = MqttShareLib::SharedClient.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                                     port: 8883,
                                     ssl: true,
                                     cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                                     key_file: "/Users/Pierre/certs/private.pem.key",
                                     ca_file: "/Users/Pierre/certs/root-CA.crt")

p = Proc.new do
  p " Hi, I AM THE CALLBACK IMPLEMENTATION"
end

cli.on_test = p

cli.connect

cli2 = MqttShareLib::SharedClient.new
cli2.host = "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com"
cli2.port = 8883
cert_file = "/Users/Pierre/certs/certificate.pem.crt"
key_file = "/Users/Pierre/certs/private.pem.key"
ca_file = "/Users/Pierre/certs/root-CA.crt"
cli2.set_tls_ssl_context(ca_file, cert_file, key_file)


cli2.connect

cli.publish("topic_1", "Hello There!")
cli2.publish("topic_2", "Hi there I am client 2")

cli2.disconnect
cli.disconnect

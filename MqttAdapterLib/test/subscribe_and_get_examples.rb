$LOAD_PATH << '~/IoT_raspberry_pi/MqttAdapterLib/lib'

require "mqtt_share_lib"

cli = MqttShareLib::ShxoaredClient.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                                     port: 8883,
                                     ssl: true,
                                     cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                                     key_file: "/Users/Pierre/certs/private.pem.key",
                                     ca_file: "/Users/Pierre/certs/root-CA.crt")
cli.connect

p "Client : #{cli}"
p "-------Host : #{cli.host}"
p "-------Port : #{cli.port}"
p "-------Ssl  : #{cli.ssl}"

cli.subscribe("topic_1")
cli.subscribe("topic_2")

on_message = Proc.new do |topic, payload|
  p "Message received on Topic : #{topic}"
  p "----------------- Payload : #{payload}"
  next "MESSAGE READ"
  p "###########################"
end

cli.get(&on_message)

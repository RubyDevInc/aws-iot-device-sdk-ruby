require 'mqtt'
require 'resolv-replace'

MQTT::Client.connect(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                     port: 8883,
                     ssl: true,
                     cert_file: "/home/pi/certs/certificate.pem.crt",
                     key_file: "/home/pi/certs/private.pem.key",
                     ca_file: "/home/pi/certs/root-CA.crt") do |client|

  client.subscribe("$aws/things/MyRasPi2/shadow/update/accepted")
  topic,message = client.get
  p [topic,message]
end

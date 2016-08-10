$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'


require "mqtt_manager"

cli = MqttManager::MqttManager.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")


cli.connect


cli.subscribe("$aws/things/MyRasPi2/shadow/get/accepted")


5.times do
  cli.publish("$aws/things/MyRasPi2/shadow/get", "")
  sleep 1
end

cli.disconnect


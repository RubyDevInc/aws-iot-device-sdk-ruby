$LOAD_PATH << '~/Iot_raspberry_pi/MqttCore/'


require "aws_mqtt_core"

cli = MqttCore::MqttCore.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")


cli.connect


cli.subscribe("topic_1")


10.times do
  cli.publish("topic_1", "Hi there, I am ruby mqtt core ^^, comming soon...")
  sleep 1
end


cli.disconnect


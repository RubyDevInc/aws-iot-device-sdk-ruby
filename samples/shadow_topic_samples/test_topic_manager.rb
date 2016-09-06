require "aws_iot_device"

manager = AwsIotDevice::MqttShadowClient::MqttManager.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")

manager.connect

cli = AwsIotDevice::MqttShadowClient::ShadowTopicManager.new(manager)

filter_callback = Proc.new do |message|
  puts "Received (through filtered callback) : "
  puts "------------------- Topic: #{message.topic}" 
  puts "------------------- Payload: #{message.payload}"
  puts "###################"
end

cli.shadow_topic_subscribe("MyRasPi2", "get", filter_callback)

sleep 1

4.times do
  cli.shadow_topic_publish("MyRasPi2", "get", "")
  sleep 1
end

manager.disconnect


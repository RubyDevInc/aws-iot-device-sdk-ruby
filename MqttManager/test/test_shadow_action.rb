$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

mqtt_client = MqttManager::MqttManager.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")

mqtt_client.connect

topic_manager = MqttManager::TopicManager.new(mqtt_client)

cli = ShadowActionManager.new("MyRasPi2", topic_manager, false)

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}"
  puts "############################################################################################################"
end

n = 1

3.times do
  cli.shadow_get(filter_callback, 4)
  puts "This is turn #{n}\n"
  n += 1
  sleep 5
end

mqtt_client.disconnect


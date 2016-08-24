$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

manager = MqttManager::MqttManager.new(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")

manager.connect

topic_manager = MqttManager::TopicManager.new(manager)

cli = ShadowActionManager.new("MyRasPi2", topic_manager, false)

filter_callback = Proc.new do |message|
  puts "Received (through filtered callback) : "
  puts "------------------- Topic: #{message.topic}" 
  puts "------------------- Payload: #{message.payload}"
  puts "###################"
end

n = 1

5.times do
  cli.shadow_get(filter_callback, 3)
  p "This is turn #{n}"
  n += 1
  sleep 1
end

manager.disconnect


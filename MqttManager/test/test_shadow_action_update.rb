$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

mqtt_client = MqttManager::MqttManager.new(host: "a2perapdhhaey0.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")

mqtt_client.connect

topic_manager = MqttManager::TopicManager.new(mqtt_client)

cli = ShadowActionManager.new("MyRasPi", topic_manager, false)

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

cli.register_shadow_delta_callback(filter_callback)

timeout = 5
n = 1

5.times do
  json_payload = "{\"state\":{\"desired\":{\"property\":\"RubySDK\",\"count\":#{n}}}}"
  cli.shadow_update(json_payload, filter_callback, timeout)
  n += 1
end

sleep 2

mqtt_client.disconnect

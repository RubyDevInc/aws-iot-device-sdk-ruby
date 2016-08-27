$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

mqtt_client = MqttManager::MqttManager.new(host: "a2perapdhhaey0.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/inaba/certs/certificate.pem.crt",
                             key_file: "/Users/inaba/certs/private.pem.key",
                             ca_file: "/Users/inaba/certs/root-CA.crt")

mqtt_client.connect

topic_manager = MqttManager::TopicManager.new(mqtt_client)

cli = ShadowActionManager.new("MyRasPi2", topic_manager, false)

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}"
  puts "############################################################################################################"
end

# n = 1
#
# 3.times do
#   cli.shadow_get(filter_callback, 4)
#   puts "This is turn #{n}\n"
#   n += 1
#   sleep 5
# end

n = 1
3.times do
	# JSONPayload = '{"state":{"desired":{"property":' + str(n) + '}}}'
  json_payload = '{"state":{"desired":{"property":"test_inaba","test":"aaaaaa"}}}'
	cli.shadow_update(json_payload, filter_callback, 5)
  puts "This is turn #{n} shadow_update\n"
  n += 1
  sleep 5
end

# n = 1
# 3.times do
# 	cli.shadow_delete( filter_callback, 5)
#   puts "This is turn #{n} shadow_delete\n"
#   n += 1
#   sleep 5
# end

mqtt_client.disconnect

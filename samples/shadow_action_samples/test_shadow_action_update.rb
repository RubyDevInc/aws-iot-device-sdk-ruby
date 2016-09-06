require 'aws_iot_device'

mqtt_client = AwsIotDevice::MqttShadowClient::MqttManager.new(host: "a2perapdhhaey0.iot.ap-northeast-1.amazonaws.com",
                             port: 8883,
                             ssl: true,
                             cert_file: "/Users/Pierre/certs/certificate.pem.crt",
                             key_file: "/Users/Pierre/certs/private.pem.key",
                             ca_file: "/Users/Pierre/certs/root-CA.crt")
mqtt_client.connect

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

timeout = 5

topic_manager = AwsIotDevice::MqttShadowClient::ShadowTopicManager.new(mqtt_client)

client = AwsIotDevice::MqttShadowClient::ShadowActionManager.new("MyRasPi", topic_manager, false)

client.register_shadow_delta_callback(filter_callback)

n = 1

5.times do
  json_payload = "{\"state\":{\"desired\":{\"property\":\"RubySDK\",\"count\":#{n}}}}"
  client.shadow_update(json_payload, filter_callback, timeout)
  n += 1
end

sleep timeout

mqtt_client.disconnect

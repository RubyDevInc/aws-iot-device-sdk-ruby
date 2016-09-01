$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "shadow_client"

rootCAPath = "/Users/Pierre/certs/root-CA.crt"
privateKeyPath = "/Users/Pierre/certs/private.pem.key"
certificatePath = "/Users/Pierre/certs/certificate.pem.crt"

host = "a2perapdhhaey0.iot.ap-northeast-1.amazonaws.com"
port = 8883

myShadowClient = ShadowClient.new
myShadowClient.configureEndpoint(host, port)
myShadowClient.configureCredentials(rootCAPath, privateKeyPath, certificatePath)

myShadowClient.connect

cli = myShadowClient.createShadowHandlerWithName('TestThing',false)

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}"
  puts "##########################################"
end

puts "Start shadow_delete\n"
cli.shadow_delete(filter_callback, 5)
sleep 1

myShadowClient.disconnect

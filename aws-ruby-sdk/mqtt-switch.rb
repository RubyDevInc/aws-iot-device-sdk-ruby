# coding: utf-8
require 'mqtt'
# require 'aws-sdk'
require 'resolv-replace'
require 'json'
require 'pi_piper'
include PiPiper

# creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
# client_iot = Aws::IoT::Client.new(region: 'ap-northeast-1', credentials: creds)
# client_iot.describe_endpoint(endpointAdress: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com")

 client = MQTT::Client.connect(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                               port: 8883,
                               ssl: true,
                               cert_file: "/home/pi/certs/certificate.pem.crt",
                               key_file: "/home/pi/certs/private.pem.key",
                               ca_file: "/home/pi/certs/root-CA.crt")
 
 puts "Press the swith to get started"
 
 @var = false
 @light = @var

 
 def press_button(cli)
   after :pin => 17, :goes => :high do |pin|
     @var = @var ? false : true
     cli.publish("$aws/things/MyRasPi2/shadow/update", { state: { 
                                                           desired: {
                                                             light: @var
                                                           },
                                                           reported: {
                                                             switch: @var,
                                                            light: @light
                                                           }
                                                         }
                                                       }.to_json)
   end   
 end


 press_button(client)
 PiPiper.wait


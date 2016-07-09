require 'mqtt'
# require 'aws-sdk'
require 'resolv-replace'
require 'json'

# creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
# client_iot = Aws::IoT::Client.new(region: 'ap-northeast-1', credentials: creds)
# client_iot.describe_endpoint(endpointAdress: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com")

MQTT::Client.connect(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                     port: 8883,
                     ssl: true,
                     cert_file: "/home/pi/certs/certificate.pem.crt",
                     key_file: "/home/pi/certs/private.pem.key",
                     ca_file: "/home/pi/certs/root-CA.crt") do |client|

  client.publish("$aws/things/MyRasPi2/shadow/update", { state: { 
                                                          desired: {
                                                            message: " Hi there!"
                                                          }
                                                        }
                                                      }.to_json)

end

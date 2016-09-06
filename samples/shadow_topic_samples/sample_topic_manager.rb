require "aws_iot_device"
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Basic usage basic_greeting.rb -c \"YOUR_CERTIFICATE_PATH\" -k \"YOUR_KEY_FILE_PATH\" -ca \"YOUR_ROOT_CA_PATH -H \"YOUR_ENDPOINT\" -p 8883\n"
  
  opts.separator ""
  opts.separator "Common options"
  opts.on_tail("-h", "--help", "--usage", "Show this message") do
    puts opts
    exit
  end
  
  opts.on("-H", "--host [END_POINT]", "The endpoint where you want to connect") do |host|
    options[:host] = host
  end
  
  opts.on("-p", "--port [MQTT_PORT]", "The port used for the connection Default is 8883") do |port|
    options[:port] = port
  end
  
  opts.on("-c", "--cert [CERT_FILE_PATH]", "The path to the certificate file of the private key.") do |cert|
    options[:cert] = cert
  end
  
  opts.on("-k", "--key [KEY_FILE_PATH]", "The path to private key file that would be used for encryption") do |key|
    options[:key] = key
  end
  
  opts.on("-a", "--root_ca [ROOT_CA_PATH]", "The path to the authority certification file") do |root_ca|
    options[:root_ca] = root_ca
  end

  opts.on("-t", "--thing [THING_NAME]", "The Thing name on which the action would be done") do |thing|
    options[:things] = thing
  end
end.parse!(ARGV)


host = options[:host]
port = options[:port] || 8883
certificate_path = options[:cert]
private_key_path = options[:key]
root_ca_path = options[:root_ca]
thing = options[:things]

manager = AwsIotDevice::MqttShadowClient::MqttManager.new(host: host,
                             port: port,
                             ssl: true,
                             cert_file: certificate_path,
                             key_file: private_key_path,
                             ca_file: root_ca_path)

manager.connect

cli = AwsIotDevice::MqttShadowClient::ShadowTopicManager.new(manager)

filter_callback = Proc.new do |message|
  puts "Received (through filtered callback) : "
  puts "------------------- Topic: #{message.topic}" 
  puts "------------------- Payload: #{message.payload}"
  puts "###################"
end

cli.shadow_topic_subscribe(thing, "get", filter_callback)

sleep 1

4.times do
  cli.shadow_topic_publish(thing, "get", "")
  sleep 1
end

manager.disconnect


require 'aws_iot_device'
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
cert_file_path = options[:cert]
key_file_path = options[:key]
ca_file_path = options[:root_ca]
thing = options[:things]

mqtt_client = AwsIotDevice::MqttShadowClient::MqttManager.new(host: host,
                             port: port,
                             ssl: true)

mqtt_client.config_ssl_context(ca_file_path, key_file_path, cert_file_path)
mqtt_client.connect

filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

timeout = 5

topic_manager = AwsIotDevice::MqttShadowClient::ShadowTopicManager.new(mqtt_client)

client = AwsIotDevice::MqttShadowClient::ShadowActionManager.new(thing, topic_manager, false)

client.register_shadow_delta_callback(filter_callback)

n = 1

5.times do
  json_payload = "{\"state\":{\"desired\":{\"property\":\"RubySDK\",\"count\":#{n}}}}"
  client.shadow_update(json_payload, timeout, filter_callback)
  n += 1
end

sleep timeout

mqtt_client.disconnect

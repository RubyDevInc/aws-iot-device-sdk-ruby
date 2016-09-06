require 'mqtt_manager'
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
end.parse!(ARGV)


host = options[:host]
port = options[:port] || 8883
cert_file_path = options[:cert]
key_file_path = options[:key]
ca_file_path = options[:root_ca] 

client = MqttManager::MqttManager.new(host: host,
                             port: port,
                             ssl: true,
                             cert_file: cert_file_path,
                             key_file: key_file_path,
                             ca_file: ca_file_path)

client2 = MqttManager::MqttManager.new

client2.config_endpoint(host, port)
client2.ssl = true
client2.config_ssl_context(ca_file_path, key_file_path, cert_file_path)

client.connect()
client2.connect()

callback = Proc.new do |message|
  p " Client1 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

callback2 = Proc.new do |message|
  p " Client2 catch message event"
  p "--- Topic: #{message.topic}"
  p "--- Payload: #{message.payload}"
end

client.subscribe("topic_2", 0, callback)
client2.subscribe("topic_1", 0,callback2)


puts "# STARTING EXAMPLE #"
sleep 2
client.publish("topic_1", "Hello Sir. My name is client 1. How do you do? ")
sleep 2
client2.publish("topic_2", "Hello Mister Client 1. My name is client 2. How do you do?")

2.times do
  client.publish("topic_1", "How do you do?")
  sleep 1
  client2.publish("topic_2", "How do you do?")
  sleep 1
end

client.disconnect
client2.disconnect

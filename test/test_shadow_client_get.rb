$LOAD_PATH << ENV['AWS_IOT_SDK_RUBY_PATH']

require 'shadow_client'
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

my_shadow_client = ShadowClient.new
my_shadow_client.configure_endpoint(host, port)
my_shadow_client.configure_credentials(root_ca_path, private_key_path, certificate_path)

my_shadow_client.connect

my_shadow_client.create_shadow_handler_with_name(thing ,false)


filter_callback = Proc.new do |message|
  puts "Executing the specific callback for topic: #{message.topic}\n##########################################\n"
end

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow(filter_callback, 4)
sleep 5

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow(nil, 4)
sleep 5

puts "##### Starting test_shadow_client_get ######"
my_shadow_client.get_shadow(filter_callback, 4)
sleep 5

my_shadow_client.disconnect

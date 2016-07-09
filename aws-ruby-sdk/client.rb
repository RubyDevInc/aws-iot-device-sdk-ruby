require 'aws-sdk'

creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])

client_dataplane = Aws::IoTDataPlane::Client.new(region: 'ap-northeast-1', endpoint: 'https://data.iot.ap-northeast-1.amazonaws.com', credentials: creds)
client_iot = Aws::IoT::Client.new(region: 'ap-northeast-1', credentials: creds)

def things_info(client) 
  resp = client.list_things()
  unless resp.things.empty?
    resp.things.each do |t|
      puts ">>>>><<<<<"
      puts t.thing_name
      puts "------"
      puts t.attributes
      puts ">>>>><<<<<"
    end
  else
    puts "No things to display"
  end
end

things_info(client_iot)

puts "      Create Thing"
resp = client_iot.create_thing({
                                 thing_name: "PierreTest",
                                 attribute_payload: {
                                   attributes: {
                                     "attr1"=> "foo",
                                     "attr2"=> "bar"
                                   },
                                 },
                               }) 
things_info(client_iot)
puts "      Delete Thing"
resp = client_iot.delete_thing({
                                 thing_name: "PierreTest"
                               })

resp = client_dataplane.publish({
                                  topic: "Topic 1",
                                  qos: 1,
                                  payload: "Hello, I did it!"
                                })


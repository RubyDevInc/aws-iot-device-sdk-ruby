require 'mqtt'
require 'resolv-replace'
require 'json'

@client = MQTT::Client.connect(host: "a15ipmbgzhr3uc.iot.ap-northeast-1.amazonaws.com",
                               port: 8883,
                               ssl: true,
                               cert_file: "/home/pi/certs/certificate.pem.crt",
                               key_file: "/home/pi/certs/private.pem.key",
                               ca_file: "/home/pi/certs/root-CA.crt")

##### TMP variable
@topics_listen = ['$aws/things/MyRasPi2/shadow/update/delta', '$aws/things/MyRasPi2/shadow/update/documents']
@topic_publish = '$aws/things/MyRasPi2/shadow/update'
#####

@subscribed_topics = [] 

def topic_subscribed?(topics)
  return @subscribed_topics.include?(topics)
end

def topics_subscription(topics_list, thing=nil)
  # TODO:
  # - Check double subscription
  # - Check topics exist
  # - Check thing right
  # - Check things exist
  @client.subscribe(topics_list)
  @subscribed_topics += topics_list
end

def topic_publish(topic, message)
  # TODO:
  # - Check topic (right, status, subscriptions)
  # - Check Message (format)
  # - Check client ? (client id ...)
  @client.publish(topic, message)
end

def listen_topic(cli, topic)  
  topic,raw_message = cli.get(topic)
    message = JSON.parse(raw_message)
    return message
end

def action_auto_synchronize(delta_message)
  unless delta_message["state"] == nil
    desired_state = delta_message["state"]
    message = { state: {
                  reported: desired_state.to_hash
                }
               }.to_json
    topic_publish(@topic_publish, message)
  end
end


topics_subscription(@topics_listen)

loop do
  message = listen_topic(@client, @subscribed_topics[0])
  action_auto_synchronize(message)
  sleep 1
 end



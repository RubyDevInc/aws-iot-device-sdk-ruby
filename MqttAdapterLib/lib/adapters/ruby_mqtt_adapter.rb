require 'mqtt'
require 'thread'

module Adapters
  class Ruby_mqtt_adapter

    attr_reader :client_id

    attr_accessor :filtered_topics

    def initialize(*args)
      @client = MQTT::Client.new(*args)
      @filtered_topics = {}
      @client_id = ""
      @client_id = generate_client_id
    end

    def client_id
      @client_id
    end

    def publish(topic, payload='', retain=false, qos=0)
      @client.publish(topic, payload, retain, qos)
    end

    def create_client(*args)
      @client = MQTT::Client.new(*args)
    end

    def connect(*args, &block)
      client = create_client(*args) if @client.nil?
      @client.connect(&block)
      loop_start
    end

    def generate_client_id(prefix='ruby', lenght=16)
      charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')
      @client_id << prefix << Array.new(lenght) { charset.sample }.join
    end

    def ssl_context
      @client.ssl_context
    end

    def disconnect(send_msg=true)
      @client.disconnect(send_msg)
    end

    def connected?
      @client.connected?
    end

    def subscribe(topics, qos=0)
      @client.subscribe(topics, qos)
    end


    def loop_start
      Thread.new{loop_forever}
    end

    def loop_stop(thread)
      thread.join
    end

    def loop_forever
      loop do
        mqtt_loop
      end
    end

    def mqtt_loop
      loop_read
      loop_write
      loop_misc
    end

    def loop_read(max_message=10)
      counter_message = 0
      while !@client.queue_empty? && counter_message <= max_message
        message = get_packet
        ### Fitlering message if matching to filtered topic
        topic = message.topic
        if @filtered_topics.key?(topic)
          callback = @filtered_topics[topic]
          callback.call(message)
        else
          on_message_callback(message)
        end
        counter_message += 1
      end
    end

    def loop_write
      ### Not implemented yet
    end

    def loop_misc
      ### Not implemented yet
    end

    def get(topic=nil, &block)
      @client.get(topic, &block)
    end

    def get_packet(topic=nil, &block)
      @client.get_packet(topic, &block)
    end

    def queue_empty?
      @client.queue_empty?
    end

    def queue_length
      @client.queue_length
    end

    def unsubscribe(*topics)
      @client.unsubscribe(*topics)
    end

    def host
      @client.host
    end

    def host=(host)
      @client.host = host
    end

    def port
      @client.port
    end


    def port=(port)
      @client.port = port
    end

    def ssl=(ssl)
      @client.ssl = ssl
    end

    def set_tls_ssl_context(ca_cert, cert=nil, key=nil)
      @client.ssl = true
      @client.ssl_context
      @client.cert_file = cert
      @client.key_file = key
      @client.ca_file = ca_cert
    end

    def on_message=(callback)
      @on_message = callback
    end

    def on_message_callback(message)
      if @on_message.is_a? Proc
        @on_message.call(message)
      end
    end

    def add_callback_filter_topic(topic, callback)
      if callback.is_a? Proc
        @filtered_topics[topic] = callback
      end
    end

    def remove_callback_filter_topic(topic)
      if @filtered_topics.key(topic)
        @filtered_topics.delete("#{topic}")
      end
    end

    #################################################
    ###################### WIP ######################
    #################################################

    def on_connect=
        block.call()
    end

    def on_disconnect
      block.call()
    end


    def on_publish(&block)
      block.call()
    end

    def on_subscribe(&block)
      block.call()
    end

    #################################################
    #################################################
    #################################################

    private

    def fake_handler(*args)
      func = @on_test
      on_test(*args, &func)
    end
  end
end

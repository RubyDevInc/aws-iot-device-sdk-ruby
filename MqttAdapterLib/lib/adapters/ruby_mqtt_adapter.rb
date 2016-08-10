require 'mqtt'
require 'thread'


# module MqttShareLib
module Adapters
  class Ruby_mqtt_adapter
    
    def initialize(*args)
      @client = MQTT::Client.new(*args)
    end
    
    def test_own
      p "I am the test function implemented by the adapter"
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
      @client.generate_client_id(prefix, lenght)
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
    
    def loop_read(max_message=4)
      counter_message = 0
      while !@client.queue_empty? and counter_message <= max_message 
        p "starting loop_read max message = #{max_message} and queue.empty? #{@client.queue_empty?}"
        message = get_packet
        on_message_callback(message)
        counter_message += 1
        p "max message is : #{max_message} and empty queue? : #{@client.queue_empty?}"
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
      @client.cert_file = cert
      @client.key_file = key
      @client.ca_file = ca_cert
    end


    def on_test=(on_test)
      @on_test = on_test
    end
    
    def on_test(*args, &block)
      p "I am at the test callback"
      if block_given?
        p " I am executing the test callabck"
        block.call(*args)
      end
    end
    
    def on_message=(callback)
      @on_message = callback
    end
    
    def on_message_callback(message)
      if @on_message.is_a? Proc
        @on_message.call(message)
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
# end

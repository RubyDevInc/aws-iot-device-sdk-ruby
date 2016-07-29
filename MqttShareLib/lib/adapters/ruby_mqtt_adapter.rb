require 'mqtt'

module MqttShareLib
  module Adapters
    module Ruby_mqtt_adapter
      extend self
      
      def test_own
        p "I am the test function implemented by the adapter"
      end
      
      def publish(client, topic, payload='', retain=false, qos=0)
        client.publish(topic, payload, retain, qos)
      end

      def create_client(*args)
        MQTT::Client.new(*args)
      end
      
      def connect(client, *args, &block)
        client = create_client(*args) if client.nil?
        client.connect(&block)
        fake_handler
      end
      
      def generate_client_id(client, prefix='ruby', lenght=16)
        res = client.generate_client_id(prefix, lenght)
        return res
      end
      
      def ssl_context(client)
        client.ssl_context
      end
      
      def disconnect(client, send_msg=true)
        client.disconnect(send_msg)
      end
      
      def connected?(client)
        client.connected?
      end
            
      def subscribe(client, *topics)
        client.subscribe(*topics)
      end
      
      def get(client, topic=nil, &block)
        client.get(topic, &block)
      end
        
      def get_packet(client, topic=nil, &block)
        client.get_packet(topic, &block)
      end

      def queue_empty?(client)
        client.queue_empty?
      end
      
      def queue_length(client)
        client.queue_length
      end
      
      def unsubscribe(client, *topics)
        client.unsubscribe(client, *topics)
      end

      def set_host(client, host)
        client.host = host
      end

      def set_port(client, port)
        client.port = port
      end

      def set_ssl(client, ssl)
        client.ssl = ssl
      end
      
      def set_tls_ssl_context(client, ca_cert, cert=nil, key=nil)
        client.ssl = true
        client.cert_file = cert
        client.key_file = key
        client.ca_file = ca_cert
      end

      ###################### WIP ######################

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
      
      def on_connect=
        block.call()
      end

      def on_disconnect
        block.call()
      end

      def on_message(&block)
        block.call()
      end

      def on_publish(&block)
        block.call()
      end

      def on_subscribe(&block)
        block.call()
      end

      private

      def fake_handler(*args)
        func = @on_test
        on_test(*args, &func)
      end
    end
  end
end

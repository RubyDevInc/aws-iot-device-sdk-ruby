require 'paho-mqtt'

module AwsIotDevice
  module MqttAdapter
    class PahoMqttAdapter

      def initialize(*args)
        @client = PahoMqtt::Client.new(args[0])
      end

      def client_id
        @client.client_id
      end

      def connect(*args, &block)
        if args.last.is_a?(Hash)
          attr = args.last
          attr.each_pair do |k, v|
            if [ :host, :port, :keep_alive, :persistent, :blocking ].include?(k)
              @client.send("#{k}=", v)
            else
              raise "Parameter error, invalid paramater \"#{k}\" for connect with paho-mqtt"
            end
          end
        end
        @client.connect
        if block_given?
          begin
            yield(self)
          ensure
            @mqtt_client.disconnect
          end
        end
      end

      def publish(topic, payload="", retain=false, qos=0)
        @client.publish(topic, payload, retain, qos)
      end

      def loop_start
        Thread.new { loop_forever }
      end

      def loop_stop(thread)
        thread.join
      end

      def loop_forever
        loop do
          @client.mqtt_loop
        end
      end
      
      def mqtt_loop
        @client.mqtt_loop
      end
      
      def loop_read
        @client.loop_read
      end

      def loop_write
        @client.loop_write
      end

      def loop_misc
        @client.loop_misc
      end

      def get(topic=nil, &block)
        @client.loop_read(1)
      end

      def get_packet(topic=nil, &block)
        @client.loop_read(1)
      end

      def generate_client_id
        @client.generate_client_id
      end

      def disconnect(send_msg)
        @client.disconnect(send_msg)
      end

      def connected?
        @client.connected?
      end

      def subscribe(topic, qos)
        @client.subscribe([topic, qos])
      end

      def subscribe_bunch(topics)
        @client.subscribe(topics)
      end
      
      def unsubscribe(topic)
        @client.unsubscribe(topic)
      end

      def unsubscribe_bunch(topics)
        @client.unsubscribe(topics)
      end
      
      def set_tls_ssl_context(ca_cert=nil, cert=nil, key=nil)
        @client.config_ssl_context(cert, key, ca_cert)
      end      
      
      def add_callback_filter_topic(topic, callback=nil, &block)
        @client.add_topic_callback(topic, callback, &block)
      end

      def remove_callback_filter_topic(topic)
        @client.remove_topic_callback(topic)
      end

      def on_connack=(callback)
        @client.on_connack = callback
      end
      
      def on_suback=(callback)
        @client.on_suback = callback
      end

      def on_unsuback=(callback)
        @client.on_unsuback = callback
      end

      def on_puback=(callback)
        @client.on_puback = callback
      end

      def on_pubrec=(callback)
        @client.on_pubrec = callback
      end

      def on_pubrel=(callback)
        @client.on_pubrel = callback 
      end

      def on_pubcomp=(callback)
        @client.on_pubcomp = callback
      end
      
      def on_message=(callback)
        @client.on_message = callback
      end
      
      def on_connack(&block)
        @client.on_connack(&block)
      end
      
      def on_suback(&block)
        @client.on_suback(&block)
      end

      def on_unsuback(&block)
        @client.on_unsuback(&block)
      end

      def on_puback(&block)
        @client.on_puback(&block)
      end

      def on_pubrec(&block)
        @client.on_pubrec(&block)
      end

      def on_pubrel(&block)
        @client.on_pubrel(&block)
      end

      def on_pubcomp(&block)
        @client.on_pubcomp(&block)
      end
      
      def on_message(&block)
        @client.on_message(&block)
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

      def ssl
        @client.ssl
      end

      def ssl=(ssl)
        @client.ssl = ssl
      end
    end
  end
end

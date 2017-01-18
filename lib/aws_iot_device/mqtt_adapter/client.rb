module AwsIotDevice
  module MqttAdapter
    class Client

      attr_reader :client_id

      ### @adapter contains the name of the adapter that should be module as a third party librairy
      ### The method call by the shared client are implemented by the third party or the adapter module itself.
      ### @adapter default value is MqttShareLib::Adapters::RubyMqttAdapter
      attr_accessor :adapter

      ### @on_'event' contains the callback's [block, Proc, lambda] that should be called when 'event' is catched
      ### Callbacks should be customized in the higher level class (ex. MqttManger or upper)
      ### Callback should be called by some (private) handlers define in the third party librairy

      ### On a MqttAdapter's create, the client adapter is set as the previously define module adapter
      ### The client is then initialize with the client type of the third librairy of the adapter.
      ### @client default type is MQTT::Client
      def initialize(*args)
        @adapter = MqttAdapter.adapter.new(*args)
      end

      def client_id
        @adapter.client_id
      end

      ### The following method represent the basics common MQTT actions.
      ### As possible, they should be implemented in the third party librairy
      ### If not, the adpater should implement them or throw and excpetion
      def connect(*args, &block)
        @adapter.connect(*args, &block)
      end

      def publish(topic, payload='', retain=false, qos=0)
        @adapter.publish(topic, payload, retain, qos)
      end

      def loop_start
        @thread = @adapter.loop_start
      end

      def loop_stop
        @adapter.loop_stop(@thread)
      end

      def loop_forever
        @adapter.loop_forever
      end

      def mqtt_loop
        @adapter.mqtt_loop
      end
      
      def loop_read
        @adapter.loop_read
      end

      def loop_write
        @adapter.loop_write
      end

      def loop_misc
        @adapter.loop_misc
      end

      def get(topic=nil, &block)
        @adapter.get(topic, &block)
      end

      def get_packet(topic=nil, &block)
        @adapter.get_packet(topic, &block)
      end

      def generate_client_id
        @adapter.generate_client_id
      end

      def disconnect(send_msg=true)
        @adapter.disconnect(send_msg)
      end

      def connected?
        @adapter.connected?
      end

      def subscribe(topic, qos)
        @adapter.subscribe(topic, qos)
      end

      def subscribe_bunch(*topics)
        @adapter.subscribe_bunch(topics)
      end
      
      def unsubscribe(topic)
        @adapter.unsubscribe(topic)
      end

      def unsubscribe_bunch(*topics)
        @adapter.unsubscribe_bunch(topics)
      end

      def set_tls_ssl_context(ca_cert, cert=nil, key=nil)
        @adapter.set_tls_ssl_context(ca_cert, cert, key)
      end

      def add_callback_filter_topic(topic, callback=nil, &block)
        @adapter.add_callback_filter_topic(topic, callback, &block)
      end

      def remove_callback_filter_topic(topic)
        @adapter.remove_callback_filter_topic(topic)
      end

      def on_connack=(callback)
        @adapter.on_connack = callback
      end
      
      def on_suback=(callback)
        @adapter.on_suback = callback
      end

      def on_unsuback=(callback)
        @adapter.on_unsuback = callback
      end

      def on_puback=(callback)
        @adapter.on_puback = callback
      end

      def on_pubrec=(callback)
        @adapter.on_pubrec = callback
      end

      def on_pubrel=(callback)
        @adapter.on_pubrel = callback
      end

      def on_pubcomp=(callback)
        @adapter.on_pubcomp = callback
      end
      
      def on_message=(callback)
        @adapter.on_message = callback
      end
      
      def on_connack(&block)
        @adapter.on_connack(&block)
      end
      
      def on_suback(&block)
        @adapter.on_suback(&block)
      end

      def on_unsuback(&block)
        @adapter.on_unsuback(&block)
      end

      def on_puback(&block)
        @adapter.on_puback(&block)
      end

      def on_pubrec(&block)
        @adapter.on_pubrec(&block)
      end

      def on_pubrel(&block)
        @adapter.on_pubrel(&block)
      end

      def on_pubcomp(&block)
        @adapter.on_pubcomp(&block)
      end
      
      def on_message(&block)
        @adapter.on_message(&block)
      end
      
      ### The following attributes should exists in every MQTT third party librairy.
      ### They are necessary (or really usefull and common) for the establishement of the connection and/or the basic Mqtt actions.
      ### The setter directely change the third party client value when the getter remote the actual SharedClient instance's attribute value
      def host
        @adapter.host
      end

      def host=(host)
        @adapter.host = host
      end

      def port
        @adapter.port
      end

      def port=(port)
        @adapter.port = port
      end

      # Boolean for the encrypted mode (true = ssl/tls | false = no encryption)
      def ssl
        @adapter.ssl
      end

      def ssl=(ssl)
        @adapter.ssl = ssl
      end
    end
  end
end

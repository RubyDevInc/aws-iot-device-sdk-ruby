require 'thread'

module AwsIotDevice
  module MqttShadowClient
    class MqttManager

      attr_reader :client_id

      attr_accessor :connection_timeout_s

      attr_accessor :mqtt_operation_timeout_s

      attr_accessor :ssl

      def initialize(*args)
        @client = create_mqtt_adapter(*args)
        @mqtt_operation_timeout_s = 2
        @mutex_publish = Mutex.new()
        @mutex_subscribe = Mutex.new()
        @mutex_unsubscribe = Mutex.new()
      end

      def host=(host)
        @client.host = host
      end

      def host
        @client.host
      end

      def port=(port)
       @client.port = port
      end

      def port
        @client.port
      end
      
      def client_id
        @client.client_id
      end

      def create_mqtt_adapter(*args)
        @client = MqttAdapter::Client.new(*args)
      end

      def config_endpoint(host, port)
        if host.nil? || port.nil?
          raise "config_endpoint error: either host || port is undefined"
        end
        @client.host = host
        @client.port = port
      end

      def config_ssl_context(ca_file, key, cert)
        self.ca_file = ca_file
        self.key = key
        self.cert = cert
        @client.set_tls_ssl_context(@ca_file, @cert, @key)
      end

      def connect(*args, &block)
        ### Execute a mqtt opration loop in background for time period defined by mqtt_connection_timeout
        @client.connect(*args, &block)
      end

      def disconnect
        @client.disconnect
      end

      def publish(topic, payload="", qos=0, retain=nil)
        if topic.nil?
          raise "publish error: topic cannot be nil"
        end
        @mutex_publish.synchronize{
          @client.publish(topic,payload, qos, retain)
        }
      end

      def subscribe(topic, qos=0, callback=nil)
        if topic.nil?
          raise "subscribe error: topic cannot be nil"
        end
        @mutex_subscribe.synchronize {
          @client.add_callback_filter_topic(topic, callback)
          @client.subscribe(topic, qos)
        }
      end

      def subscribe_bunch(*topics)
        @mutex_subscribe.synchronize {
          topics.each do |topic|
            @client.add_callback_filter_topic(topic.first, topic.pop) if !topic[2].nil? && topic[2].is_a?(Proc)
          end
          @client.subscribe_bunch(topics)
        }
      end
      
      def unsubscribe(topic)
        if topic.nil?
          raise "unsubscribe error: topic cannot be nil"
        end
        @mutex_unsubscribe.synchronize{
          @client.remove_callback_filter_topic(topic)
          @client.unsubscribe(topic)
        }
      end

      def unsubscribe_bunch(*topics)
        @mutex_unsubscribe.synchronize {
          topics.each do |topic|
            @client.remove_callback_filter_topic(topic)
          end
          @client.unsubscribe_bunch(topics)
        }
      end

      def on_connack=(callback)
        @client.on_connack = callback if paho_client?
      end

      def on_suback=(callback)
        @client.on_suback = callback if paho_client?
      end

      def on_unsuback=(callback)
        @client.on_unsuback = callback if paho_client?
      end

      def on_puback=(callback)
        @client.on_puback = callback if paho_client?
      end

      def on_pubrec=(callback)
        @client.on_pubrec = callback if paho_client?
      end

      def on_pubrel=(callback)
        @client.on_pubrel = callback if paho_client?
      end

      def on_pubcomp=(callback)
        @client.on_pubcomp = callback if paho_client?
      end

      def on_message=(callback)
        @client.on_message = callback
      end

      def on_connack(&block)
        @client.on_connack(&block) if paho_client?
      end

      def on_suback(&block)
        @client.on_suback(&block) if paho_client?
      end

      def on_unsuback(&block)
        @client.on_unsuback(&block) if paho_client?
      end

      def on_puback(&block)
        @client.on_puback(&block) if paho_client?
      end

      def on_pubrec(&block)
        @client.on_pubrec(&block) if paho_client?
      end

      def on_pubrel(&block)
        @client.on_pubrel(&block) if paho_client?
      end

      def on_pubcomp(&block)
        @client.on_pubcomp(&block) if paho_client?
      end

      def on_message(&block)
        @client.on_message(&block)
      end

      def add_topic_callback(topic, callback, &block)
        @client.add_callback_filter_topic(topic, callback, &block)
      end

      def remove_topic_callback(topic)
        @client.remove_callback_filter_topic(topic)
      end

      def paho_client?
        @client.adapter.class == MqttAdapter::PahoMqttAdapter
      end

      private

      def cert=(path)
        @cert = path
      end

      def key=(path)
        @key = path
      end

      def ca_file=(path)
        @ca_file = path
      end
    end
  end
end

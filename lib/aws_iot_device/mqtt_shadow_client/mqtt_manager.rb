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
      
      def cert_file=(path)
        @cert = path
      end

      def key_file=(path)
        @key = path
      end

      def ca_file=(path)
        @ca_file = path
      end

      def client_id
        @client.client_id
      end

      def create_mqtt_adapter(*args)
        @client = MqttAdapter::Client.new(*args)
      end

      def config_endpoint(host, port)
        if host.nil? || port.nil?
          raise "config_endpoint error: either host || port is undefined error"
        end
        @client.host = host
        @client.port = port
      end

      def config_ssl_context(ca_file, key, cert)
        @ca_file = ca_file
        @key = key
        @cert = cert
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
          @client.publish(topic,payload,qos,retain)
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
        @client.subscribe_bunch(topics.flatten)
      end
      
      def unsubscribe(topics)
        if topics.nil?
          raise "unsubscribe error: topic cannot be nil"
        end
        @mutex_unsubscribe.synchronize{
          topics.each do |topic|
            @client.remove_callback_filter_topic(topic)
          end
          @client.unsubscribe(topics)
        }
      end

      def unsubscribe_bunch(*topics)
        @client.unsubscribe(topivd.flatten)
      end

      def add_topic_callback(topic, callback, &block)
        @client.add_callback_filter_topic(topic, callback, &block)
      end

      def remove_topic_callback(topic)
        @client.remove_callback_filter_topic(topic)
      end
    end
  end
end

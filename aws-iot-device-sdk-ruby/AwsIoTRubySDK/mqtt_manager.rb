$LOAD_PATH << ENV['MQTT_ADAPTER_PATH']

require 'mqtt_adapter_lib'
require 'thread'

module MqttManager
  class MqttManager

    attr_reader :client_id

    attr_accessor :connection_timeout_s

    attr_accessor :mqtt_operation_timeout_s

    attr_accessor :host

    attr_accessor :port

    attr_accessor :ssl

    def initialize(*args)
      @client = create_mqtt_adapter(*args)
      @mutex_publish = Mutex.new()
      @mutex_subscribe = Mutex.new()
      @mutex_unsubscribe = Mutex.new()
      @ssl_configured = false
      
      if args.last.is_a?(Hash)
        attr = args.pop
        attr.each_pair do |k, v|
          self.send("#{k}=", v)
        end
      end
      
      if need_ssl_configure?
        @client.set_tls_ssl_context(@ca_file, @cert, @key)
        @ssl_configured = true
      end

      ### Set the on_message's callback
      @client.on_message = Proc.new do |userdata, message|
        on_message_callback(userdata, message)
      end
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
      @client = MqttAdapterLib::MqttAdapter.new(*args)
    end

    def on_message_callback(message)
      puts "Received (with no custom callback registred) : "
      puts "------------------- Topic: #{message.topic}"
      puts "------------------- Payload: #{message.payload}"
    end

    def config_endpoint(host, port)
      if host.nil? || port.nil?
        raise "config_endpoint error: either host || port is undefined error"
      end
      @host = host
      @port = port
    end

    def config_ssl_context(ca_file, key, cert)
      @ca_file = ca_file
      @key = key
      @cert = cert
      @client.set_tls_ssl_context(ca_file, cert, key)
    end

    def connect(keep_alive_interval=30, &block)
      if keep_alive_interval.nil? && keep_alive_interval.is_a(Integer)
        raise "connect error: keep_alive_interval cannot be a not nil Interger"
      end

      @client.host=(@host)
      @client.port=(@port)
      ### Execute a mqtt opration loop in background for time period defined by mqtt_connection_timeout
      @client.connect(block)
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
      ret = false
      @mutex_subscribe.synchronize {
        @client.add_callback_filter_topic(topic, callback)
        @client.subscribe(topic)
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

    def need_ssl_configure?
      !( @ca_file.nil? || @cert.nil? || @key.nil? ) && @ssl
    end
  end
end

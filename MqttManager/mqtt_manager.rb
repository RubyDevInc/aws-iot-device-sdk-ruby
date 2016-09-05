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
      # TODO manage MQTT event and execute corresponding callback with the following variables
      # @offline_publish_queue = MqttCore::Utils::OfflineQueue.new
      # @mutex_offline_publish_queue = Mutex.new()
      # @draining_interval_s = 1
      # @connect_result = nil
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

    def on_message_callback(message, userdata={})
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
      # if need_ssl_configure? && !@ssl_configured
      @client.set_tls_ssl_context(ca_file, cert, key)
      #    @ssl_configured = true
      #  else
      #     raise "config_ssl_context: Cannot set proper new ssl context for the connection.\n A ssl context might have already been intialized for this client."
      #  end
    end

    def connect(keep_alive_interval=30, &block)
      if keep_alive_interval.nil? && keep_alive_interval.is_a(Integer)
        raise "connect error: keep_alive_interval cannot be a not nil Interger"
      end

      @client.host=(@host)
      @client.port=(@port)
      ### Execute a mqtt opration loop in background for time period defined by mqtt_connection_timeout
      @client.connect(block)
      ##### TODO : waiting for connack && change connection result (fron maxInt to 0) || send disconnect
    end

    def disconnect
      @client.disconnect
      ##### TODO : waiting for disconnack && change disconnection result (fron maxInt to 0) || send error
    end

    def publish(topic, payload="", qos=0, retain=nil)
      ### TODO: add testing part on connection status
      ### TODO: add push to offlinequeue
      ### TODO: add draining queue check
      if topic.nil?
        raise "publish error: topic cannot be nil"
      end
      ret = false
      @mutex_publish.synchronize{
        rc = @client.publish(topic,payload,qos,retain)
        # TODO: implement return code (for publish)
        rc = 0
        ret = rc == 0
        unless ret == true
          raise "publish error: publish faild with code #{rc}"
        end
      }
      ret
    end

    def subscribe(topic, qos=0, callback=nil)
      if topic.nil?
        raise "subscribe error: topic cannot be nil"
      end
      ret = false
      @mutex_subscribe.synchronize {
        ### TODO: add set_callback to topic
        @client.add_callback_filter_topic(topic, callback) unless callback.nil?
        rc = @client.subscribe(topic)
        ### TODO: add subscirbe callback && suback management
        rc = 0
        ret = rc == 0
      }
      ret
    end

    def unsubscribe(topic)
      if topic.nil?
        raise "unsubscribe error: topic cannot be nil"
      end
      ret = false
      @mutex_unsubscribe.synchronize{
        @client.remove_callback_filter(topic)
        rc = @client.unsubscribe(topic)
        ### TODO: add unsubscribe && unsuback management
        rc = 0
        ret  = rc == 0       
      }
      ret
    end

    ###########################################################
    ##################### DO NOT USE! #########################
    ########## Not Implemented in current version #############
    ###########################################################
    def config_iam_credentials(aws_access_key_id, aws_secret_access_key, aws_session_token)
      if aws_access_key_id.nil? || aws_secret_access_key.nil? ||  aws_session_token.nil?
        raise "config_iam_credentials error: aws_access_key_id, aws_secret_access_key || aws_session_token is undefined but required"
      end
      @client.config_iam_credentials(aws_access_key_id, aws_secret_access_key, aws_session_token)
    end
    
    def resubscribe_pool
      if @subscribed_topics.lenght > 0
        @subscribed_topics.each do |topic, qos, callback|
          self.subscribe(topic, qos, callback)
        end
      end
    end

    def drain_publish_queue
      while @offline_publish_queue.empty?
        @mutex_offline_publish_queue.synchronize {
          topic, payload, qos = @offline_publish_queue.pop
          @client.publish(topic, payload, qos)
          sleep @draining_interval_s
        }
      end
    end

    def set_offline_publish_queueing(queue_size, drop_behavior)
      if queue_size.nil? || drop_behavior.nil?
        raise "setOffliePublishQueueing error: queue_size || drop_behavior is undefined but required"
      end
      @offline_publish_queue = MqttCore::Utils::OfflineQueue.new(queue_size, drop_behavior)
    end

    def set_draining_interval_s(draining_interval_s)
    end

    def on_connect(userdata={}, flags, rc)
      @connect_result = rc
      if @connect_result == 0
        subscription_thread = Thread.new { resubscribe_pool }
      end

      if @subscribed_topics.empty?
        draining_thread = Thread.new { drain_publish_queue}
      end
    end

    def on_disconnect
    end

    def on_subscribe
    end

    def on_unsubscribe
    end

    def set_backoff_time(base_reconnect_time_s, maximum_reconnect_time_s, minimum_connect_time_s)
      if base_reconnect_time_s.nil? || maximum_reconnect_time_s ||  minimum_connect_time_s.nil?
        raise "set_backoff_time error: base_reconnect_time_s, maximum_reconnect_time_s || minimum_connect_time_s is undefined but required"
      end
      @client.set_backoffTime(base_reconnect_time_s, maximum_reconnect_time_s, minimum_connect_time_s)
      puts "base_reconnect_time_s have been set to: #{base_reconnect_time_s} second(s)"
      puts "maximum_reconnect_time_s have been set to: #{maximum_reconnect_time_s} second(s)"
      puts "minimum_connect_time_s have been set to: #{minimum_connect_time_s} second(s)"
    end
    ###########################################################
    ###########################################################
    ###########################################################


    private


    def need_ssl_configure?
      !( @ca_file.nil? || @cert.nil? || @key.nil? ) && @ssl
    end
  end
end

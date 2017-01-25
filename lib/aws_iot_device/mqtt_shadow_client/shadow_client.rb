require 'aws_iot_device/mqtt_shadow_client/mqtt_manager'
require 'aws_iot_device/mqtt_shadow_client/shadow_topic_manager'
require 'aws_iot_device/mqtt_shadow_client/shadow_action_manager'

module AwsIotDevice
  module MqttShadowClient
    class ShadowClient

      def initialize(*args)
        unless args.last.nil?
          config_attr(args.last)
        else
          @mqtt_client = MqttManager.new
        end
      end

      def connect(*args, &block)
        @mqtt_client.connect(*args)
        self.logger.info("Connected to the AWS IoT platform") if logger?
        if block_given?
          begin
            yield(self)
          ensure
            @mqtt_client.disconnect
          end
        end
      end

      def create_shadow_handler_with_name(shadow_name, persistent_subscribe=false)
        @action_manager = ShadowActionManager.new(shadow_name, @mqtt_client, persistent_subscribe)
      end

      def logger=(logger_path)
        file = File.open(logger_path, "a+")
        log_file = Logger.new(file)
        log_file.level = Logger::DEBUG
        @action_manager.logger = log_file
      end

      def logger
        @action_manager.logger
      end

      def logger?
        @action_manager.logger?
      end

      def get_shadow(timeout=5, callback=nil, &block)
        @action_manager.shadow_get(timeout, callback, &block)
      end

      def update_shadow(payload, timeout=5, callback=nil, &block)
        @action_manager.shadow_update(payload, timeout, callback, &block)
      end

      def delete_shadow(timeout=5, callback=nil, &block)
        @action_manager.shadow_delete(timeout, callback, &block)
      end

      def register_get_callback(callback=nil, &block)
        @action_manager.register_get_callback(callback, &block)
      end

      def register_update_callback(callback=nil, &block)
        @action_manager.register_update_callback(callback, &block)
      end

      def register_delete_callback(callback=nil, &block)
        @action_manager.register_delete_callback(callback, &block)
      end

      def register_delta_callback(callback=nil, &block)
        @action_manager.register_shadow_delta_callback(callback, &block)
      end

      def remove_delta_callback
        @action_manager.remove_shadow_delta_callback
      end

      def remove_get_callback
        @action_manager.remove_get_callback
      end

      def remove_update_callback
        @action_manager.remove_update_callback
      end

      def remove_delete_callback
        @action_manager.remove_delete_callback
      end

      def disconnect
        @mqtt_client.disconnect
      end

      def configure_endpoint(host, port)
        @mqtt_client.config_endpoint(host,port)
      end

      def configure_credentials(ca_file, key, cert)
        @mqtt_client.config_ssl_context(ca_file, key, cert)
      end


      private

      def config_attr(args)
        shadow_attr = args.dup
        shadow_attr.keep_if {|key| key == :shadow_name || key == :persistent_subscribe || key == :logger }
        mqtt_attr = args        
        mqtt_attr.delete_if {|key| key == :shadow_name || key == :persistent_subscribe || key == :logger }
        @mqtt_client = MqttManager.new(mqtt_attr)
        shadow_attr[:persistent_subscribe] ||= false
        @action_manager = create_shadow_handler_with_name(shadow_attr[:shadow_name], shadow_attr[:persistent_subsrcibe]) if shadow_attr.has_key?(:shadow_name)
      end
    end
  end
end

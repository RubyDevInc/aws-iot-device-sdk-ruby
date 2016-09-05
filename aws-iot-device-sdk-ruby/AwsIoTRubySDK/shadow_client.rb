LOAD_PATH << ENV['AWS_IOT_SDK_RUBY_PATH']

require 'mqtt_manager'
require 'shadow_topic_manager'
require 'shadow_action_manager'

class ShadowClient
  attr_accessor :action_manager

  def initialize
    @mqtt_client = MqttManager::MqttManager.new
  end

  def connect
    @mqtt_client.connect
  end

  def topic_manager
    @topic_manager = MqttManager::TopicManager.new(@mqtt_client)
  end

  def create_shadow_handler_with_name(shadow_name, is_persistent_subscribe=false)
    topic_manager
    @action_manager = ShadowActionManager.new(shadow_name, @topic_manager, is_persistent_subscribe)
  end

  def get_shadow(callback=nil, timeout=5)
    @action_manager.shadow_get(callback, timeout)
  end

  def update_shadow(payload, callback=nil, timeout=5)
    @action_manager.shadow_update(payload, callback, timeout)
  end

  def delete_shadow(callback=nil, timeout=5)
    @action_manager.shadow_delete(callback, timeout)
  end

  def register_delta_callback(callback)
    @action_manager.register_shadow_delta_callback(callback)
  end

  def remove_shadow_delta_callback
    @action_manager.remove_shadow_delta_callback
  end

  def disconnect
    @mqtt_client.disconnect
  end

  def configure_endpoint(host,port)
    @mqtt_client.config_endpoint(host,port)
  end

  def configure_credentials(ca_file, key, cert)
    @mqtt_client.config_ssl_context(ca_file, key, cert)
  end
end

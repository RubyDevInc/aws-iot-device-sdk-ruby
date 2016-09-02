$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

class ShadowClient
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
    ShadowActionManager.new(shadow_name, @topic_manager, is_persistent_subscribe)
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

$LOAD_PATH << '~/Iot_raspberry_pi/MqttManager/'

require "mqtt_manager"
require "shadow_topic_manager"
require "shadow_action_manager"

class ShadowClient
  def initialize
    @host = ""
    @port = ""
    @srcCAFile = ""
    @srcKey = ""
    @srcCert = ""
    @mqtt_client = MqttManager::MqttManager.new
  end

  def connect
    @mqtt_client.connect
  end

  def topicManager
    @topic_manager = MqttManager::TopicManager.new(@mqtt_client)
  end

  def createShadowHandlerWithName(shadowName, isPersistentSubscribe)
    topicManager
    ShadowActionManager.new(shadowName, @topic_manager, isPersistentSubscribe)
  end

  def disconnect
    @mqtt_client.disconnect
  end

  def configureEndpoint(host,port)
    @mqtt_client.config_endpoint(host,port)
  end

  def configureCredentials(srcCAFile, srcKey, srcCert)
    @mqtt_client.config_ssl_context(srcCAFile, srcKey, srcCert)
  end

end

require 'aws_iot/mqtt_shadow_client/topic_builder'

module AwsIot
  module MqttShadowClient
    class TopicManager

      def initialize(mqtt_manager)
        if mqtt_manager.nil?
          raise "TopicAction_error: TopicAction should be initialized with a mqtt_manager but was undefined"
        end
        @mqtt_manager = mqtt_manager
        @sub_unsub_mutex = Mutex.new()
      end

      def client_id
        @mqtt_manager.client_id
      end

      def shadow_topic_publish(shadow_name, shadow_action, payload)
        topic = TopicBuilder.new(shadow_name, shadow_action)
        @mqtt_manager.publish(topic.get_topic_general, payload, false, 0)
      end

      def shadow_topic_subscribe(shadow_name, shadow_action, callback=nil)
        @sub_unsub_mutex.synchronize(){
          topic = TopicBuilder.new(shadow_name, shadow_action)
          if topic.is_delta?(shadow_action)
            @mqtt_manager.subscribe(topic.get_topic_delta, 0, callback)
          else
            @mqtt_manager.subscribe(topic.get_topic_accepted, 0, callback)
            @mqtt_manager.subscribe(topic.get_topic_rejected, 0, callback)
          end
        }
        sleep 2
      end

      def shadow_topic_unsubscribe(shadow_name, shadow_action)
        @sub_unsub_mutex.synchronize(){
          topic = TopicBuilder.new(shadow_name, shadow_action)
          if topic.is_delta?(shadow_name)
            @mqtt_manager.unsubscribe(topic.get_topic_delta)
          else
            @mqtt_manager.unsubscribe(topic.get_topic_accepted)
            @mqtt_manager.unsubscribe(topic.get_topic_rejected)
          end
        }
      end
    end
  end
end

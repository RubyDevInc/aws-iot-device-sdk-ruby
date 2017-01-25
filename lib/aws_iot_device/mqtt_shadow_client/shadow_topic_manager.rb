require 'aws_iot_device/mqtt_shadow_client/topic_builder'

module AwsIotDevice
  module MqttShadowClient
    class ShadowTopicManager

      def initialize(mqtt_manager, shadow_name)
        raise ArgumentError, "topic manager should be initialized with a mqtt_manager but was undefined" if mqtt_manager.nil?
        raise ArgumentError, "topic manager should be initialize with a mqtt mmanager but was undefined" if shadow_name.nil?

        @mqtt_manager = mqtt_manager
        @sub_unsub_mutex = Mutex.new()
        @topic = TopicBuilder.new(shadow_name)
        @timeout = mqtt_manager.mqtt_operation_timeout_s
      end

      def shadow_topic_publish(action, payload)
        @mqtt_manager.publish(@topic.get_topic_general(action), payload, false, 0)
      end

      def shadow_topic_subscribe(action, callback=nil)
        @sub_unsub_mutex.synchronize() {
          @subacked = false
          if @topic.is_delta?(action)
            @mqtt_manager.subscribe(@topic.get_topic_delta, 0, callback)
          else
            @mqtt_manager.subscribe_bunch([@topic.get_topic_accepted(action), 1, callback], [@topic.get_topic_rejected(action), 1, callback])
          end
        }
      end
          
      def shadow_topic_unsubscribe(action)
        @sub_unsub_mutex.synchronize(){
          @unsubacked = false
          if @topic.is_delta?(action)
            @mqtt_manager.unsubscribe(@topic.get_topic_delta)
          else
            @mqtt_manager.unsubscribe_bunch(@topic.get_topic_accepted(action), @topic.get_topic_rejected(action))
          end
        }
      end

      def retrieve_action(topic)
        res = nil
        ACTION_NAME.each do |action|
          if topic[0] == @topic.get_topic_accepted(action)
            res = action.to_sym
            break
          end
        end
        res
      end

      def paho_client?
        @mqtt_manager.paho_client?
      end

      def on_suback=(callback)
        @mqtt_manager.on_suback = callback
      end

      def on_suback(&block)
        @mqtt_manager.on_suback(&block)
      end

      def on_unsuback=(callback)
        @mqtt_manager.on_unsuback = callback 
      end

      def on_unsuback(&block)
        @mqtt_manager.on_unsuback(&block)
      end
    end
  end
end

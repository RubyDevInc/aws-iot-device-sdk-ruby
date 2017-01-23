require 'aws_iot_device/mqtt_shadow_client/topic_builder'

module AwsIotDevice
  module MqttShadowClient
    class ShadowTopicManager

      def initialize(mqtt_manager, shadow_name)
        if mqtt_manager.nil?
          raise "TopicAction_error: TopicAction should be initialized with a mqtt_manager but was undefined"
        end

        if shadow_name.nil?
          raise "TopicAction_error: shadow name is required for TopicBuilder"
        end
        @mqtt_manager = mqtt_manager
        @sub_unsub_mutex = Mutex.new()
        if @mqtt_manager.paho_client?
          @mqtt_manager.on_suback = proc { @subacked = true }
          @mqtt_manager.on_unsuback = proc { @unsubacked = true }
        end
        @subacked = false
        @unsubacked = false
        @topic = TopicBuilder.new(shadow_name)
        @timeout = @mqtt_manager.mqtt_operation_timeout_s
      end

      def client_id
        @mqtt_manager.client_id
      end

      def shadow_topic_publish(action, payload)
        @mqtt_manager.publish(@topic.get_topic_general(action), payload, false, 0)
      end

      def shadow_topic_subscribe(action, callback=nil, timeout=@timeout)
        @sub_unsub_mutex.synchronize() {
          @subacked = false
          if @topic.is_delta?(action)
            @mqtt_manager.subscribe(@topic.get_topic_delta, 0, callback)
          else
           @mqtt_manager.subscribe_bunch([@topic.get_topic_accepted(action), 0, callback], [@topic.get_topic_rejected(action), 0, callback])
          end
          handle_timeout(@subacked)
        }
        @subacked
      end
      
          
      def shadow_topic_unsubscribe(action, timeout=@timeout)
        @sub_unsub_mutex.synchronize(){
          @unsubacked = false
          if @topic.is_delta?(action)
            @mqtt_manager.unsubscribe(@topic.get_topic_delta)
          else
            @mqtt_manager.unsubscribe_bunch(@topic.get_topic_accepted(action), @topic.get_topic_rejected(action))
          end
          handle_timeout(@unsubacked)
        }
        @unsubacked
      end
      
      
      private
      
      def handle_timeout(flag)
        if @mqtt_manager.paho_client?
          ref = Time.now + timeout
          while !flag && Time.now <= ref do
            sleep 0.001
          end
        else
          sleep 2
          flag = true
        end
      end
    end
  end
end

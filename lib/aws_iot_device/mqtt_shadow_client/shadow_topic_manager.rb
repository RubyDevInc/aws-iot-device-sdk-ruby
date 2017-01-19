require 'aws_iot_device/mqtt_shadow_client/topic_builder'

module AwsIotDevice
  module MqttShadowClient
    class ShadowTopicManager

      def initialize(mqtt_manager)
        if mqtt_manager.nil?
          raise "TopicAction_error: TopicAction should be initialized with a mqtt_manager but was undefined"
        end
        @mqtt_manager = mqtt_manager
        @sub_unsub_mutex = Mutex.new()
        if @mqtt_manager.paho_client?
          @mqtt_manager.on_suback = proc { @subacked = true }
          @mqtt_manager.on_unsuback = proc { @unsubacked = true }
        end
        @subacked = false
        @unsubacked = false
        @timeout = @mqtt_manager.mqtt_operation_timeout_s
      end

      def client_id
        @mqtt_manager.client_id
      end

      def shadow_topic_publish(shadow_name, shadow_action, payload)
        topic = TopicBuilder.new(shadow_name, shadow_action)
        @mqtt_manager.publish(topic.get_topic_general, payload, false, 0)
      end

      def shadow_topic_subscribe(shadow_name, shadow_action, callback=nil, timeout=@timeout)
        @sub_unsub_mutex.synchronize() {
          @subacked = false
          topic = TopicBuilder.new(shadow_name, shadow_action)
          if topic.is_delta?(shadow_action)
            @mqtt_manager.subscribe(topic.get_topic_delta, 0, callback)
          else
            @mqtt_manager.subscribe_bunch([topic.get_topic_accepted, 0, callback], [topic.get_topic_rejected, 0, callback])
          end
          if @mqtt_manager.paho_client?
            ref = Time.now + timeout
            while !@subacked && valid_packet(ref) do
              sleep 0.001
            end
          else
            sleep 2
            @subacked = true
          end
        }
        @subacked
      end

      def shadow_topic_unsubscribe(shadow_name, shadow_action, timeout=@timeout)
        @sub_unsub_mutex.synchronize(){
          @unsubacked = false
          topic = TopicBuilder.new(shadow_name, shadow_action)
          if topic.is_delta?(shadow_name)
            @mqtt_manager.unsubscribe(topic.get_topic_delta)
          else
            @mqtt_manager.unsubscribe_bunch(topic.get_topic_accepted, topic.get_topic_rejected)
          end
          if @mqtt_manager.paho_client?
            ref = Time.now + timeout
            while !@unsubacked && valid_packet(ref) do
              sleep 0.001
            end
          else
            sleep 2
            @unsubacked = true
          end
        }
        @unsubacked
      end


      private

      def valid_packet(ref)
        Time.now >= ref
      end
    end
  end
end

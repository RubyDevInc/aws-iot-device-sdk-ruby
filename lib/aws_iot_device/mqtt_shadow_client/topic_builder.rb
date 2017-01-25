module AwsIotDevice
  module MqttShadowClient
    class TopicBuilder
      def initialize(shadow_name)
        raise ArgumentError, "topic_builder initialization, shadow_name is required but undefined" if shadow_name.nil?
        
        @shadow_name = shadow_name
        
        @topic_delta = "$aws/things/#{shadow_name}/shadow/update/delta"
        @topic_general = "$aws/things/#{shadow_name}/shadow/"
      end

      def is_delta?(action)
        action == ACTION_NAME[3]
      end

      def get_topic_general(action)
        raise ArgumentError, "topic_builder, get topic, unreconized action_name \"#{action}\"" unless ACTION_NAME.include?(action)
        @topic_general + action
      end

      def get_topic_accepted(action)
        get_topic_general(action) + "/accepted"
      end

      def get_topic_rejected(action)
        get_topic_general(action) + "/rejected"
      end

      def get_topic_delta
        @topic_delta
      end
    end
  end
end

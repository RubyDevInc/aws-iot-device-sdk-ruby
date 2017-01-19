module AwsIotDevice
  module MqttShadowClient
    class TopicBuilder
      ACTION_NAME = %w(get update delete delta).freeze

      def initialize(shadow_name)
        if shadow_name.nil?
          raise "shadow_name_error: shadow_name is required but undefined"

        end

        @shadow_name = shadow_name

        @topic_delta = "$aws/things/#{shadow_name}/shadow/update/delta"
        @topic_general = "$aws/things/#{shadow_name}/shadow/"
      end

      def is_delta?(action)
        action == ACTION_NAME[3]
      end

      def get_topic_general(action)
        unless ACTION_NAME.include?(action)
          raise "action_name_error: unreconized action_name \"#{action}\""
        end
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

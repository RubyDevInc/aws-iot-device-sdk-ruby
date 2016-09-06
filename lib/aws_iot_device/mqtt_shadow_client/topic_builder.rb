module AwsIotDevice
  module MqttShadowClient
    class TopicBuilder
      ACTION_NAME = %w(get update delete delta).freeze

      def initialize(shadow_name, action_name)
        unless ACTION_NAME.include?(action_name)
          raise "action_name_error: unreconized action_name \"#{action_name}\""
        end

        if shadow_name.nil?
          raise "shadow_name_error: shadow_name is required but undefined"

        end

        @shadow_name = shadow_name
        @action_name = action_name

        ### The case of delta's action
        if is_delta?(action_name)
          @topic_delta = "$aws/things/#{shadow_name}/shadow/update/delta"
        else
          @topic_general = "$aws/things/#{shadow_name}/shadow/#{action_name}"
          @topic_accepted = "$aws/things/#{shadow_name}/shadow/#{action_name}/accepted"
          @topic_rejected = "$aws/things/#{shadow_name}/shadow/#{action_name}/rejected"
        end
      end

      def is_delta?(action_name)
        action_name == ACTION_NAME[3]
      end

      def get_topic_general
        @topic_general
      end

      def get_topic_accepted
        @topic_accepted
      end

      def get_topic_rejected
        @topic_rejected
      end

      def get_topic_delta
        @topic_delta
      end
    end
  end
end

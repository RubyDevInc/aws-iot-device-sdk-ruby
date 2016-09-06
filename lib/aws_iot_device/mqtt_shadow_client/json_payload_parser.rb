require 'securerandom'
require 'timers'
require 'thread'
require 'json'

module AwsIotDevice
  module MqttShadowClient
    class JSONPayloadParser
      ### This class acts as Basic JSON parser.
      ### The answer from AWS is in a JSON format.
      ### All different key of the JSON file should be defined as hash key

      def initialize
        @message = {}
      end

      def set_message(message)
        @message = JSON.parse(message)
      end

      def get_attribute_value(key)
        @message[key]
      end

      def set_attribute_value(key, value)
        @message[key] = value
      end

      def get_json
        @message.to_json
      end
    end
  end
end

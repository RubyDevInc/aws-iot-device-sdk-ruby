require 'securerandom'
require 'timers'
require 'thread'
require 'json'

module AwsIotDevice
  module MqttShadowClient
    class TokenCreator
      ### This class manage the clients token.
      ### Every actions receive a token for a certian interval, meaning that action is waiting to be proceed.
      ### When token time run out or the actions have been treated token should deleted.

      def initialize(shadow_name, client_id)
        if shadow_name.length > 16
          @shadow_name = shadow_name[0..15]
        else
          @shadow_name = shadow_name
        end
        @client_id = client_id
        @sequence_number = 0
      end

      def create_next_token
        token = ""
        token << "#{@client_id}" << "_" << "#{@shadow_name}" << "_" << "#{@sequence_number}" << "_" << "#{random_token_string(5)}"
      end

      private

      def random_token_string(lenght)
        charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'9')
        Array.new(lenght) { charset.sample }.join
      end
    end
  end
end

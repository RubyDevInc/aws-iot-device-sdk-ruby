require 'securerandom'
require 'timers'
require 'thread'
require 'json'
require 'aws_iot_device/mqtt_shadow_client/token_creator'
require 'aws_iot_device/mqtt_shadow_client/json_payload_parser'

module AwsIotDevice
  module MqttShadowClient
    class ShadowActionManager
      ### This the main AWS action manager
      ### It allows to execute the AWS actions (get, update, delete)
      ### It allows to manage the time out after an action have been start
      ### Actions request are send on the general actions topic and answer is retreived from accepted/refused/delta topics

      def initialize(shadow_name, shadow_topic_manager, persistent_subscribe=false)
        @shadow_name = shadow_name
        @topic_manager = shadow_topic_manager
        @payload_parser = JSONPayloadParser.new
        @is_subscribed = {}
        @is_subscribed[:get] = false
        @is_subscribed[:update] = false
        @is_subscribed[:delete] = false
        @token_handler = TokenCreator.new(shadow_name, shadow_topic_manager.client_id)
        @persistent_subscribe = persistent_subscribe
        @last_stable_version = -1 #Mean no currentely stable
        @topic_subscribed_callback = {}
        @topic_subscribed_callback[:get] = nil
        @topic_subscribed_callback[:update] = nil
        @topic_subscribed_callback[:delta] = nil
        @topic_subscribed_task_count = {}
        @topic_subscribed_task_count[:get] = 0
        @topic_subscribed_task_count[:update] = 0
        @topic_subscribed_task_count[:delete] = 0
        @token_pool = {}
        @general_action_mutex = Mutex.new
        @default_callback = Proc.new do |message|
          do_default_callback(message)
        end
      end

      ### The default callback that is called by every actions
      ### It acknowledge the accepted status if action success
      ### Call a specific callback for each actions if it defined have been register previously
      def do_default_callback(message)
        @general_action_mutex.synchronize(){
          topic = message.topic
          action = parse_action(topic)
          type = parse_type(topic)
          payload = message.payload
          @payload_parser.set_message(payload)
          if %w(get update delete).include?(action)
            token = @payload_parser.get_attribute_value("clientToken")
            if @token_pool.has_key?(token)
              if type.eql?("accepted")
                new_version = @payload_parser.get_attribute_value("version")
                if new_version && new_version >= @last_stable_version
                  type.eql?("delete") ? @last_stable_version = -1 : @last_stable_version = new_version
                  Thread.new { @topic_subscribed_callback[action.to_sym].call(message) } unless @topic_subscribed_callback[action.to_sym].nil?
                else
                  puts "CATCH AN UPDATE BUT OUTDATED/INVALID VERSION (= #{new_version}) FOR TOKEN #{token}\n"
                end
              end
              @token_pool[token].cancel
              @token_pool.delete(token) 
              @topic_subscribed_task_count[action.to_sym] -= 1
              if @topic_subscribed_task_count[action.to_sym] <= 0
                @topic_subscribed_task_count[action.to_sym] = 0
                unless @persistent_subscribe
                  @topic_manager.shadow_topic_unsubscribe(@shadow_name, action)
                  @is_subscribed[action.to_sym] = false
                end
              end
            end
          elsif %w(delta).include?(action)
            new_version = @payload_parser.get_attribute_value("version")
            if new_version && new_version >= @last_stable_version
              @last_stable_version = new_version
              Thread.new { @topic_subscribed_callback[action.to_sym].call(message) } if @topic_subscribed_callback[action.to_sym]
            else
              puts "CATCH A DELTA BUT OUTDATED/INVALID VERSION (= #{new_version})\n"
            end
          end
        }
      end

      ### Should cancel the token after a preset time interval
      def timeout_manager(action_name, token)
        @general_action_mutex.synchronize(){
          if @token_pool.has_key?(token)
            action = action_name.to_sym
            @token_pool.delete(token)
            puts "The #{action_name} request with the token #{token} has timed out!\n"
            @topic_subscribed_task_count[action] -= 1
            unless @topic_subscribed_task_count[action] <= 0
              @topic_subscribed_task_count[action] = 0
              unless @persistent_subscribe
                @topic_manager.shadow_topic_unsubscribe(@shadow_name, action)
                @is_subscribed[action.to_sym] = false
              end
            end
            unless @topic_subscribed_callback[action].blank?
              puts "Shadow request with token: #{token} has timed out."
              @topic_subscribed_callback[action].call("REQUEST TIME OUT", "timeout", token)
            end
          end
        }
      end

      ### Send and publish packet with an empty payload contains in a valid JSON format.
      ### A unique token is generate and send in the packet in order to trace the action.
      ### Subscribe to the two get/accepted and get/rejected of the coresponding shadow.
      ### If the request is accpeted, the answer would be send on the get/accepted topic.
      ### It contains all the details of the shadow state in JSON document.
      ### A specific callback in Proc could be send parameter.
      ### Before exit, the function start a timer count down in the separate thread.
      ### If the time ran out, the timer_handler function is called and the get action is cancelled using the token.
      ###
      ### Parameter:
      ###   > callback: the Proc to execute when the answer to th get request would be received.
      ###                It should accept three different paramter:
      ###                  - payload : the answer content
      ###                  - response_status : among ['accepted', 'refused', 'delta']
      ###                  - token : the token assoicate to the get request
      ###
      ###   > timeout: the period after which the request should be canceled and timer_handler should be call
      ###
      ### Returns :
      ###   > the token associate to the current action (which also store in @token_pool)

      def shadow_get(callback=nil, timeout=5)
        current_token = ""
        json_payload = ""
        timer = Timers::Group.new
        @general_action_mutex.synchronize(){
          @topic_subscribed_callback[:get] = callback
          @topic_subscribed_task_count[:get] += 1
          current_token = @token_handler.create_next_token
          timer.after(timeout){ timeout_manager(:get, current_token) }
          @payload_parser.set_attribute_value("clientToken",current_token)
          json_payload = @payload_parser.get_json
          unless @is_subscribed[:get]
            @topic_manager.shadow_topic_subscribe(@shadow_name, "get", @default_callback)
            @is_subscribed[:get] = true
          end
          @topic_manager.shadow_topic_publish(@shadow_name, "get", json_payload)
          @token_pool[current_token] = timer
          Thread.new{ timer.wait }
          current_token
        }
      end

      def shadow_update(payload, callback, timeout)
        current_token = Symbol
        timer = Timers::Group.new
        json_payload = ""
        @general_action_mutex.synchronize(){
          if callback.is_a?(Proc)
            @topic_subscribed_callback[:update] = callback
          end
          @topic_subscribed_task_count[:update] += 1
          current_token = @token_handler.create_next_token
          timer.after(timeout){ timeout_manager(:update, current_token) }
          @payload_parser.set_message(payload)
          @payload_parser.set_attribute_value("clientToken",current_token)
          json_payload = @payload_parser.get_json
          unless @is_subscribed[:update]
            @topic_manager.shadow_topic_subscribe(@shadow_name, "update", @default_callback)
            @is_subscribed[:update] = true
          end
          @topic_manager.shadow_topic_publish(@shadow_name, "update", json_payload)
          @token_pool[current_token] = timer
          Thread.new{ timer.wait }
          current_token
        }
      end

      def shadow_delete(callback, timeout)
        current_token = Symbol
        timer = Timers::Group.new
        json_payload = ""
        @general_action_mutex.synchronize(){
          if callback.is_a?(Proc)
            @topic_subscribed_callback[:delete] = callback
          end
          @topic_subscribed_task_count[:delete] += 1
          current_token = @token_handler.create_next_token
          timer.after(timeout){ timeout_manager(:delete, current_token) }
          @payload_parser.set_attribute_value("clientToken",current_token)
          json_payload = @payload_parser.get_json
          unless @is_subscribed[:delete]
            @topic_manager.shadow_topic_subscribe(@shadow_name, "delete", @default_callback)
            @is_subscribed[:delete] = true
          end
          @topic_manager.shadow_topic_publish(@shadow_name, "delete", json_payload)
          @token_pool[current_token] = timer
          Thread.new{ timer.wait }
          current_token
        }
      end

      def register_shadow_delta_callback(callback)
        @general_action_mutex.synchronize(){
          @topic_subscribed_callback[:delta] = callback
          @topic_manager.shadow_topic_subscribe(@shadow_name, "delta", @default_callback)
        }
      end

      def remove_shadow_delta_callback
        @general_action_mutex.synchronize(){
          @topic_subscribe_callback.delete[:delta]
          @topic_manager.shadow_topic_unsubscribe(@shadow_name, "delta")
        }
      end

      private

      def parse_shadow_name(topic)
        topic.split('/')[2]
      end

      def parse_action(topic)
        if topic.split('/')[5] == "delta"
          topic.split('/')[5]
        else
          topic.split('/')[4]
        end
      end

      def parse_type(topic)
        topic.split('/')[5]
      end
    end
  end
end

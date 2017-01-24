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
      ### It enables the AWS IoT actions (get, update, delete)
      ### It enables the time control the time out after an action have been start
      ### Actions requests are send on the general actions topic and answer is retreived from accepted/refused/delta topics

      def initialize(shadow_name, mqtt_client, persistent_subscribe=false)
        @shadow_name = shadow_name
        @topic_manager = ShadowTopicManager.new(mqtt_client, shadow_name)
        @payload_parser = JSONPayloadParser.new
        @is_subscribed = {}
        @is_subscribed[:get] = false
        @is_subscribed[:update] = false
        @is_subscribed[:delete] = false
        @token_handler = TokenCreator.new(shadow_name, mqtt_client.client_id)
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
        @token_callback = {}
        @task_count_mutex = Mutex.new
        @token_mutex = Mutex.new
        @parser_mutex = Mutex.new
        set_basic_callback
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

      def shadow_get(timeout=5, callback=nil, &block)
        shadow_action(:get, "", timeout, callback, &block)
      end

      def shadow_update(payload, timeout=5, callback=nil, &block)
        shadow_action(:update, payload, timeout, callback, &block)
      end

      def shadow_delete(timeout=5, callback=nil, &block)
        shadow_action(:delete, "", timeout, callback, &block)
      end

      def register_get_callback(callback, &block)
        register_action_callback(:get, callback, &block)
      end

      def register_update_callback(callback, &block)
        register_action_callback(:update, callback, &block)
      end

      def register_delete_callback(callback, &block)
        register_action_callback(:delete, callback, &block)
      end

      def register_shadow_delta_callback(callback, &block)
        if callback.is_a?(Proc)
          @topic_subscribed_callback[:delta] = callback
        elsif block_given?
          @topic_subscribed_callback[:delta] = block
        end
        @topic_manager.shadow_topic_subscribe("delta", @default_callback)
      end

      def remove_get_callback
        remove_action_callback(:get)
      end

      def remove_update_callback
        remove_action_callback(:update)
      end

      def remove_delete_callback
        remove_action_callback(:delete)
      end

      def remove_shadow_delta_callback
        @topic_subscribe_callback.delete[:delta]
        @topic_manager.shadow_topic_unsubscribe("delta")
      end


      private

      def shadow_action(action, payload="", timeout=5, callback=nil, &block)
        current_token = Symbol
        timer = Timers::Group.new
        json_payload = ""
        @token_mutex.synchronize(){
          current_token = @token_handler.create_next_token
        }
        timer.after(timeout){ timeout_manager(action, current_token) }
        @parser_mutex.synchronize {
          @payload_parser.set_message(payload) unless payload == ""
          @payload_parser.set_attribute_value("clientToken", current_token)
          json_payload = @payload_parser.get_json
        }
        handle_subscription(action, timeout) unless @is_subscribed[action]
        @topic_manager.shadow_topic_publish(action.to_s, json_payload)
        @task_count_mutex.synchronize {
          @topic_subscribed_task_count[action] += 1
        }
        @token_pool[current_token] = timer
        register_token_callback(current_token, callback, &block)
        Thread.new{ timer.wait }
        current_token
      end

      ### Should cancel the token after a preset time interval
      def timeout_manager(action_name, token)
        if @token_pool.has_key?(token)
          action = action_name.to_sym
          @token_pool.delete(token)
          @token_callback.delete(token)
          puts "The #{action_name} request with the token #{token} has timed out!\n"
          @task_count_mutex.synchronize {
            @topic_subscribed_task_count[action] -= 1
            unless @topic_subscribed_task_count[action] <= 0
              @topic_subscribed_task_count[action] = 0
              unless @persistent_subscribe
                @topic_manager.shadow_topic_unsubscribe(action)
                @is_subscribed[action.to_sym] = false
              end
            end
          }
        end
      end

      def set_basic_callback
        @default_callback = proc { |message| do_message_callback(message) }

        @topic_manager.on_suback = lambda do |topics|
          action = retrieve_action(topics[0])
          @is_subscribed[action] ||= true unless action.nil?
        end

        @topic_manager.on_unsuback = lambda do |topics|
          action = retrive_action(topics)
          @is_subscribed[action] = false if action.nil?
        end
      end

      def register_token_callback(token, callback, &block)
        if callback.is_a?(Proc)
          @token_callback[token] = callback
        elsif block_given?
          @token_callback[token] = block
        end
      end

      def remove_token_callback(token)
        @token_callback.delete(token)
      end

      def register_action_callback(action, callback, &block)
        if callback.is_a?(Proc)
          @topic_subscribed_callback[action] = callback
        elsif block_given?
          @topic_subscribed_callback[action] = block
        end
      end

      def remove_action_callback(action)
        @topic_subscribed_callback[action] = nil
      end

      def decresase_task_count(action)
        @topic_subscribed_task_count[action] -= 1
        if @topic_subscribed_task_count[action] <= 0
          @topic_subscribed_task_count[action] = 0
          unless @persistent_subscribe
            @topic_manager.shadow_topic_unsubscribe(action.to_s)
            @is_subscribed[action] = false
          end
        end
      end

      ### The default callback that is called by every actions
      ### It acknowledge the accepted status if action success
      ### Call a specific callback for each actions if it defined have been register previously
      def do_message_callback(message)
        topic = message.topic
        action = parse_action(topic)
        type = parse_type(topic)
        payload = message.payload
        token = nil
        new_version = -1
        @parser_mutex.synchronize() {
          @payload_parser.set_message(payload)
          new_version = @payload_parser.get_attribute_value("version")
          token = @payload_parser.get_attribute_value("clientToken")
        }
        if %w(get update delete).include?(action)
          if @token_pool.has_key?(token)
            @token_pool[token].cancel
            @token_pool.delete(token)
            if type.eql?("accepted")
              do_accepted(message, action.to_sym, type, token, new_version)
            else
              @token_callback.delete(token)
            end
            @task_count_mutex.synchronize {
              decresase_task_count(action.to_sym)
            }
          end
        elsif %w(delta).include?(action)
          do_delta(message)
        end
      end

      def do_accepted(message, action, type, token, new_version)
        if new_version && new_version >= @last_stable_version
          type.eql?("delete") ? @last_stable_version = -1 : @last_stable_version = new_version
          Thread.new do
            @topic_subscribed_callback[action].call(message)  unless @topic_subscribed_callback[action].nil?
            @token_callback[token].call(message) if @token_callback.has_key?(token)
            @token_callback.delete(token)
          end
        else
          puts "CATCH AN UPDATE BUT OUTDATED/INVALID VERSION (= #{new_version})\n"
        end
      end

      def do_delta(message)
        new_version = @payload_parser.get_attribute_value("version")
        if new_version && new_version >= @last_stable_version
          @last_stable_version = new_version
          Thread.new { @topic_subscribed_callback[:delta].call(message) } unless @topic_subscribed_callback[:delta].nil?
        else
          puts "CATCH A DELTA BUT OUTDATED/INVALID VERSION (= #{new_version})\n"
        end
      end

      def handle_subscription(action, timeout)
        @topic_manager.shadow_topic_subscribe(action.to_s, @default_callback)
        if @topic_manager.paho_client?
          ref = Time.now + timeout
          while !@is_subscribed[action] && handle_timeout(ref) do
            sleep 0.0001
          end
        else
          sleep 2
        end
      end

      def handle_timeout(ref)
        Time.now <= ref
      end

      def retrieve_action(topics)
        actions = { :get => '/shadow/get/accepted',
                    :update => '/shadow/update/accepted',
                    :delete => '/shadow/delete/accepted' }
        res = nil
        actions.each_pair do |action, filter|
          if topics[0] == '$aws/things/' + @shadow_name + filter
            res = action
            break
          end
        end
        res
      end

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

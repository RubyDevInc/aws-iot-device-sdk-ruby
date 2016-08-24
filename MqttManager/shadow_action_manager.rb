require 'securerandom'
require 'timers'
require 'thread'

class TokenCreator
  ### This class manage the clients token.
  ### Every actions receive a token for a certian interval, meaning that action is waiting to be proceed.
  ### When token time run out or the actions have been treated token should deleted.
  
  def initialize(shadow_name, client_id)
    @shadow_name = shadow_name
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

class JSONPayloadParser
  ### This class acts as Basic JSON parser.
  ### The answer from AWS is in a JSON format.
  ### All different key of the JSON file should be defined as hash key
  
end

class ShadowActionManager
  ### This the main AWS action manager
  ### It allow to execute the AWS actions (get, update, delete)
  ### It the means time it also manage the answer of the action
  ### Actions request are send on the general actions topic and answer is retreived from accepted/refused/delta topics
  
  def initialize(shadow_name, shadow_topic_manager, persistent_subscription=flase)
    @shadow_name = shadow_name
    @topic_manager = shadow_topic_manager
    @payload_parser = JSONPayloadParser.new
    
    @token_handler = TokenCreator.new(shadow_name, shadow_topic_manager.client_id)
    @persistent_susbcribe = persistent_subscription
    @last_stable_version = -1 #Mean no currentely stable
    @is_get_subscribed = false
    @is_update_subscribed = false
    @is_delete_subscribed = false
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
      do_default_callback_example(message)
    end
  end

  def do_default_callback_example(message)
    puts "THIS IS THE EXAMPLE DEFAULT CALLBACK"
    @general_action_mutex.synchronize(){
      if message
      topic = message.topic
      action = parse_action(topic)
      type = parse_type(topic)
      @topic_subscribed_task_count[:get] -= 1
      puts "Task on get : #{@topic_subscribed_task_count[:get]}"
            
      puts "----------------------------------------------------------------------------------------------------"
      puts "------------------- Topic: #{message.topic}" 
      puts "------------------- Payload: #{message.payload}"
      puts "----------------------------------------------------------------------------------------------------"

      thr = Thread.new { @topic_subscribed_callback[action.to_sym].call(message) } if @topic_subscribed_callback[action.to_sym]
      end          
    }
  end

  
  # The default callback that is called by every actions
  # It acknowledge the accepted status if action success and call a specific callback for each actions if defined
  def do_default_callback(message)    
    @general_action_mutex.synchronize(){
      topic = message.topic
      action = parse_action(topic)
      type = parse_type(topic)
          
      if %(get update delte).include?(action)
        ### Retrieve String from JSON Parser
        token = payload_parser.get_value_from_key(:clientToken)
        if token
          puts "shadow message client token: #{token}"
          if type.eql?("accepted")
            new_version = payload_parser.get_value_from_key(:version)
            if new_version && @token_pool.has_key?(token) && new_version > @last_stable_version
              type.eql?("delete") ? @last_stable_version = -1 : @last_stable_version = new_version
            end
            @token_pool[token].cancel
            @token_pool.delete[token]
            @topic_subscribed_task_count[action.to_sym] -= 1
            if @persitent_subscribe && @topic_subscribed_task_count[action.to_sym] <= 0
              @topic_subscribed_task_count[action] = 0
              @topic_manager.shadow_topic_subscribe(@shadow_name, action_name)
            end
            thr = Thread.new { @topic_subscribed_callback[action.to_sym].call } if @topic_subscribed_callback[action.to_sym]
          end            
        end
      elsif %(delta).include?(action)
        ### Format Payload from JSON to Hash/String
        if payload_parser.valid_json || true
          new_version = payload_parser.get_value_from_key(:version)
          if new_version && new_version > @last_stable_version = new_version
            @last_stable_version = new_version
            thr = Thread.new { @topic_subscribed_callback[action.to_sym].call } if @topic_subscribed_callback[action.to_sym]
          end
        end
      end
     }
  end
  
  # Should cancel the token after a preset time interval
  def timeout_manager(action_name, token)
    puts "The #{action_name} request with the token #{token} has timed out!"
    @general_action_mutex.synchronize(){
      tk = token
      action = action_name.to_sym
      @token_pool.delete[token]
      @topic_subscribed_task_count[action] -= 1
      if @persitent_subscribe && @topic_subscribed_task_count[action] <= 0
        @topic_subscribed_task_count[action] = 0
        @topic_manager.shadow_topic_subscribe(@shadow_name, action_name)
      end
      unless @topic_subscribed_callback[action].blank?
        puts "Shadow request with token: #{token} has timed out."
        @topic_subscribed_callback[action].call("REQUEST TIME OUT", "timeout", token)
      end
    }
  end

  def shadow_get(callback, timeout)
    current_token = Symbol
    json_payload = ""
    @general_action_mutex.synchronize(){
      @topic_subscribed_callback[:get] = callback
      @topic_subscribed_task_count[:get] += 1
      current_token = @token_handler.create_next_token
      timer = Timers::Group.new
      timer.after(timeout){ timeout_manager(:get, current_token) }
      ### Build payload from string to JSON format
      ### json_payload = @payload_parser(payload)
      unless @persistent_subscribe && @is_get_subscribed
        @topic_manager.shadow_topic_subscribe(@shadow_name, "get", @default_callback)
        @is_get_subscribed = true
      end
    }
    @topic_manager.shadow_topic_publish(@shadow_name, "get", "")
    @token_pool[current_token] = Thread.new{ timer.wait }
    current_token
  end

  def shadow_update(payload, callback, timeout)
  end

  def shadow_delete(payload, callback, timeout)
  end

  def register_shadow_delta_callback(callback)
  end

  def remove_shadow_delta_callback(callback)
  end

  private

  def parse_shadow_name(topic)
    topic.split('/')[2]
  end

  def parse_action(topic)
    topic.split('/')[4]
  end

  def parse_type(topic)
    topic.split('/')[5]
  end
end

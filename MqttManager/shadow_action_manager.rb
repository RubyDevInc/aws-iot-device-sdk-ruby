require 'securerandom'
require 'timers'
require 'thread'
require 'json'

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

  def initialize
    @message = {}
  end

  def set_message(messgae)
    @message = JSON.parse(messgae)
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


  def get_timestamp(messgae)
    hash = JSON.parse(messgae)
    hash["timestamp"]
  end

  def get_version(messgae)
    hash = JSON.parse(messgae)
    hash["version"]
  end

  def get_token(messgae)
    hash = JSON.parse(messgae)
    hash["clientToken"]
  end

  def set_client_token(rawString, token)
    hash = {rawString => token}
    hash.to_json
  end

  def set_hash(messgae)
    hash = JSON.parse(messgae)
  end

  def set_json(hash)
    messgae = hash.to_json
  end

end

class ShadowActionManager
  ### This the main AWS action manager
  ### It allows to execute the AWS actions (get, update, delete)
  ### It allows to manage the time out after an action have been start
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
      # do_default_callback_example(message)
      do_default_callback(message)
    end
  end

  def do_default_callback_example(message)
    puts "EXECUTING THE EXAMPLE DEFAULT CALLBACK"
    @general_action_mutex.synchronize(){
      if message
        topic = message.topic
        action = parse_action(topic)
        type = parse_type(topic)
        @topic_subscribed_task_count[action.to_sym] -= 1
        puts "---------------------------------------------------------------------------------------------------------------------------"
        puts "------------------- Topic: #{message.topic}"
        puts "------------------- Payload: #{message.payload}"
        puts "---------------------------------------------------------------------------------------------------------------------------"
        thr = Thread.new { @topic_subscribed_callback[action.to_sym].call(message) } if @topic_subscribed_callback[action.to_sym]
      end
    }
  end

  ### The default callback that is called by every actions
  ### It acknowledge the accepted status if action success
  ### Call a specific callback for each actions if it defined have been register previously
  def do_default_callback(message)
    @general_action_mutex.synchronize(){
      topic = message.topic
      # action = parse_action(topic).to_sym
      action = parse_action(topic)
      puts "action:#{action}"
      type = parse_type(topic)
      payload = message.payload
      if %(get update delte).include?(action)
        ### Retrieve String from JSON Parser
        # TODO: if @payload_parser.is_valid_payload(payload)
        # token = @payload_parser.get_value_from_key(:clientToken)
        token = @payload_parser.get_token(payload)
        if @token_pool.has_key?(token)
          puts "shadow message client token: #{token}"
          if type.eql?("accepted")
            new_version = @payload_parser.get_version(payload)
            if new_version && @token_pool.include?(token) && new_version > @last_stable_version
              type.eql?("delete") ? @last_stable_version = -1 : @last_stable_version = new_version
            end
            puts '****accepted inaba****'
            puts @token_pool[token]
            puts '****@token_pool inaba****'
            @token_pool[token].cancel
            # Thread.kill(@token_pool[token])
            puts '**** inaba****'
            puts "**1***#{@token_pool}*****"
            @token_pool.delete(token)
            puts "**2***#{@token_pool}*****"
            @topic_subscribed_task_count[action.to_sym] -= 1
            puts '**** inaba topic_subscribed_task_count****'
            # unless @persitent_subscribe
            #   puts '**** inaba persitent_subscribe****'
            #   @topic_subscribed_task_count[action] = 0 if @topic_subscribed_task_count[action] <= 0
            #   @topic_manager.shadow_topic_unsubscribe(@shadow_name, action.to_s)
            # end
          end
        end
        puts '**** inaba Thread****'
        puts "@topic_subscribed_callback[action]#{@topic_subscribed_callback[action]}"
        # @topic_subscribed_callback[action.to_sym].call
        # thr = Thread.new { @topic_subscribed_callback[action].call } if @topic_subscribed_callback[action]
        thr = Thread.new { @topic_subscribed_callback[action.to_sym].call(message) } if @topic_subscribed_callback[action.to_sym]
        puts thr
      elsif %(delta).include?(action)
        ### Format Payload from JSON to Hash/String
        # TODO: if @payload_parser.is_valid_payload(payload)
        # new_version = payload_parser.get_value_from_key(:version)
        if new_version && new_version > @last_stable_version = new_version
          @last_stable_version = new_version
          thr = Thread.new { @topic_subscribed_callback[action].call } if @topic_subscribed_callback[action]
        end
      end
    }
  end

  ### Should cancel the token after a preset time interval
  def timeout_manager(action_name, token)
    puts "The #{action_name} request with the token #{token} has timed out!"
    @general_action_mutex.synchronize(){
      tk = token
      action = action_name
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
    current_token = Symbol
    json_payload = ""
    timer = Timers::Group.new
    @general_action_mutex.synchronize(){
      if callback.is_a?(Proc)
        @topic_subscribed_callback[:get] = callback
      end
      @topic_subscribed_task_count[:get] += 1
      current_token = @token_handler.create_next_token
      timer.after(timeout){ timeout_manager(:get, current_token) }
      ### Build payload from string to JSON format
      ### TODO : Set valid payload with client token
      ### @payload_parser.set_client_token("clientToken", current_token)
      json_payload = @payload_parser.set_client_token("clientToken", current_token)
    }
    unless @persistent_subscribe && @is_get_subscribed
      @topic_manager.shadow_topic_subscribe(@shadow_name, "get", @default_callback)
      @is_get_subscribed = true
    end
    @topic_manager.shadow_topic_publish(@shadow_name, "get", json_payload)
    @token_pool[current_token] = Thread.new{ puts "STARTING TIMER FOR TOKEN #{current_token}"; timer.wait }
    current_token
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
      # hash_payload["clientToken"] = current_token
      json_payload = @payload_parser.get_json
    }
    # unless @persistent_subscribe && @is_get_subscribed
    unless @is_get_subscribed
      @topic_manager.shadow_topic_subscribe(@shadow_name, "update", @default_callback)
      @is_get_subscribed = true
      sleep 2
    end

    @topic_manager.shadow_topic_publish(@shadow_name, "update", json_payload)
    # @token_pool[current_token] = Thread.new{ puts "STARTING TIMER FOR TOKEN #{current_token} UPDATE"; timer.wait }
    @token_pool[current_token] = timer
    # @token_pool[current_token] =
    Thread.new{ puts "STARTING TIMER FOR TOKEN #{current_token} UPDATE"; timer.wait }
    current_token
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

      hash_payload = @payload_parser.set_hash('{}')
      hash_payload["clientToken"] = current_token
      json_payload = @payload_parser.set_json(hash_payload)
    }
    unless @persistent_subscribe && @is_get_subscribed
      @topic_manager.shadow_topic_subscribe(@shadow_name, "delete", @default_callback)
      @is_get_subscribed = true
    end
    @topic_manager.shadow_topic_publish(@shadow_name, "delete", json_payload)
    @token_pool[current_token] = Thread.new{ puts "STARTING TIMER FOR TOKEN #{current_token} DETETE"; timer.wait }
    current_token
  end

  def register_shadow_delta_callback(callback)
    @general_action_mutex.synchronize(){
      @topic_subscribed_callback[:delta] = callback
    }
    @topic_manager.shadow_topic_subscribe(@shadow_name, "delta", @default_callback)
  end

  def remove_shadow_delta_callback(callback)
    @general_action_mutex.synchronize(){
      @topic_subscribe_callback.delete[:delta]
    }
    @topic_manager.shadow_topic_unsubscribe(@shadow_name, "delta")
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



class TokenCreator
  ### This class manage the clients token.
  ### Every actions receive a token for a certian interval, meaning that action is waiting to be proceed.
  ### When token time run out or the actions have been treated token should deleted.
  
  def initialize(shadow_name, client_id)
    @shadow_name = shdow_name
    @client_id = client_id
    @seque_number = 0
  end

  def create_next_token
  end

  private

  def random_token_string
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
    
    @token_handler = TokenCreator.new(shadow_name, shadow_topic_manger.client_id)
    @persistent_susbcribe = persitent_subscribe
    @last_stable_version = -1 #Mean no currentely stable
    @is_get_subscribed = false
    @is_update_subscribed = false
    @is_delete_subscribed = false
    @topic_susbcribed_callback = {}
    @topic_subscribed_callback[:get] = ""
    @topic_subscribed_callback[:update] = ""
    @topic_subscribed_callback[:delta] = ""
    @topic_subcribed_task_count = {}
    @topic_subcribed_task_count[:get] = 0
    @topic_subcribed_task_count[:update] = 0
    @topic_subcribed_task_count[:delete] = 0
    @token_pool = {}
    @general_action_mutex = Mutex.new
  end


  # The default callback that is called by every actions
  # It acknowledge the accepted status if action success and call a specific callback for each actions if defined
  def default_callback(message)
  end

  # Should cancel the token after a preset time interval
  def timer_manager(action_name, token)
  end

  def shadow_get(payload, callback, timeout)
  end

  def shadow_update(payload, callback, timeout)
  end

  def shadow_delete(payload, callback, timeout)
  end

  def register_shadow_callback(callback)
  end

  def remove_shadow_callback(callback)
  end
end

module MqttManager
  ACTION_NAME = %w(get update delete delta).freeze

  class TopicBuilder

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

  class TopicManager

    def initialize(mqtt_manager)
      if mqtt_manager.nil?
        raise "TopicAction_error: TopicAction should be initialized with a mqtt_manager but was undefined"
      end
      @mqtt_manager = mqtt_manager
      @sub_unsub_mutex = Mutex.new()
    end

    def client_id
      @mqtt_manager.client_id
    end

    def shadow_topic_publish(shadow_name, shadow_action, payload)
      topic = TopicBuilder.new(shadow_name, shadow_action)
      @mqtt_manager.publish(topic.get_topic_general, payload, false, 0)
    end

    def shadow_topic_subscribe(shadow_name, shadow_action, callback)
      @sub_unsub_mutex.synchronize(){
        topic = TopicBuilder.new(shadow_name, shadow_action)
        if topic.is_delta?(shadow_action)
          @mqtt_manager.subscribe(topic.get_topic_delta, 0, callback)
        else
          @mqtt_manager.subscribe(topic.get_topic_accepted, 0, callback)
          @mqtt_manager.subscribe(topic.get_topic_rejected, 0, callback)
        end
      }
      # TODO subscribeが完了するまで少し待つ、秒数ではなくcallbackなどを受けるようにしたいo
      sleep 2
    end

    def shadow_topic_unsubscribe(shadow_name, shadow_action)
      @sub_unsub_mutex.synchronize(){
        topic = TopicBuilder.new(shadow_name, shadow_name)
        if topic.is_delta?(action_name)
          @mqtt_manager.unsubscribe(topic.get_topic_delta)
        else
          @mqtt_manager.unsubscribe(topic.get_topic_accepted)
          @mqtt_manager.unsubscribe(topic.get_topic_refused)
        end
      }
    end
  end
end

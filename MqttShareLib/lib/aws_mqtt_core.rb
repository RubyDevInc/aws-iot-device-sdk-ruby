$LOAD_PATH << "."

require "mqtt_share_lib"
require 'thread'

class MqttCore

  attr_reader :client_id

  attr_accessor :connection_timeout_s

  attr_accessor :mqtt_operation_timeout_s

  def initialize()
    @client = create_shared_client()
    @offline_publish_queue = Queue.new
    @mutex_offline_publish_queue = Mutex.new()
    @draining_interval_s = 1
    @connect_result = nil
    # Array of Hash or Nested Hash?
    @subscribed_topics = []
  end
  
  def create_shared_client()
    @client = MqttShareLib::SharedClient.new
  end

  def resubscribe_pool(self)
    if @subscribed_topics.lenght > 0
      @subscribed_topics.each do |topic, qos, callback|
        self.subscribe(topic, qos, callback)        
      end
    end
  end
  
  def drain_publish_queue
    while @offline_publish_queue.empty?
      @mutex_offline_publish_queue.synchronize {
        topic, payload, qos = @offline_publish_queue.pop
        @client.publish(topic, payload, qos)
        sleep @draining_interval_s
      }
    end
  end

  def on_connect(client, userdata={}, flags, rc)
    @connect_result = rc
    if @connect_result == 0
      subscription_thread = Thread.new { resubscribe_pool }      
    end
    
    if @subscribed_topics.empty?
      draining_thread = Thread.new { drain_publish_queue}
    end
  end
  
end

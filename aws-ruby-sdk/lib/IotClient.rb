require 'mqtt'

class IotClient

  def createMqttClient(*args)
    return MQTT::Client.new(args)
  end

  def _reconnect
  end
  
  def _reSubscribe
    unless subscribedPool.blank?
      self.client.subscribe(subscribedPool)
    end
  end

  def generateClientId
    self.client
  end
  
  def _drainOfflineQueue
    while !self.queue.empty? do |publish_request|
      publish_request = self.client.offlineQueue.pop
      self.client.publish(publish.request.topic)
    end
  end
    
  def initialize(*args)
    self.client = createMqttClient(args)
      @connectionTimeOut = 30
      @operationTimeOut = 5 
      @subscribedPool = []
      @offlineQueue = Queue.new
  end
  
  def connect
    # Initialize Client
    # Open listening Thread
  end

  def subscribe
  end
  
  def disconnect
  end

  private

  def connectionTimeOut=()
  end

  def operation
end

module MqttShareLib
  extend self
  
  def adapter
    return @adapter if @adapter
    self.adapter = :ruby_mqtt_adapter
    @adapter
  end
  
  def adapter=(adapter_lib)
    case adapter_lib
    when Symbol, String
      require"adapters/#{adapter_lib}"
      @adapter = MqttShareLib::Adapters.const_get("#{adapter_lib.to_s.capitalize}")
    else
      raise "Missing client adapters for the lib #{adapter_lib}"
    end
  end

  class SharedClient
    # Restrict access to the base client
    # attr_accessor :client

    ### @adapter contains the name of the adapter that should be module as a third party librairy
    ### The method call by the shared client are implemented by the third party or the adapter module itself.
    ### @adapter default value is MqttShareLib::Adapters::Ruby_mqtt_adapter
    attr_accessor :adapter

    # A example function used only to test the callback calling stack.
    attr_accessor :on_test

    ### @on_'event' contains the callback's [block, Proc, lambda] that should be called when 'event' is catched
    ### Callbacks should be define in the upper class (ex. MqqtCore)
    ### Callback shoudlbe called by some (private) handlers define in the third party librairy
    
    attr_accessor :on_connect
    attr_accessor :on_disconnet
    attr_accessor :on_publish
    attr_accessor :on_subscribe
    attr_accessor :on_unbscribe
    attr_accessor :on_message


    ### On instanciation of a SharedClient, the client adapter is set as the previously define module adapter
    ### The client is then initialize with the client type of the third librairy of the adapter.
    ### @client default type is MQTT::Client
    def initialize(*args)
      @adapter = ::MqttShareLib.adapter
      @client = adapter.create_client(*args)
    end


    ### The following method represent the basics common MQTT actions.
    ### As possible, they should be implemented in the third party librairy
    ### If not, the adpater should implement them or throw and excpetion
    def connect(*args, &block)
      @adapter.connect(@client, *args, &block)
    end
    
    def create_client(*args)
      @adapter.create_client(*args)
    end

    def publish(topic, payload='', retain=false, qos=0)
      @adapter.publish(@client, topic, payload, retain, qos)
    end

    def get(topic=nil, &block)
      @adapter.get(@client, topic, &block)
    end
    
    def get_packet(topic=nil, &block)
      @adapter.get_packet(@client, topic, &block)
    end
    
    def generate_client_id
      @adapter.generate_client_id(@client)
    end
    
    def disconnect(send_msg=true)
      @adapter.disconnect(@client, send_msg)
    end
    
    def connected?
      @adapter.connected?(@client)
    end
    
    def subscribe(*topics)
      @adapter.subscribe(@client, *topics)
    end
    
    def unsubscribe(*topics)
      @adapter.unsubscribe(@client, *topics)
    end

    def set_tls_ssl_context(ca_cert, cert=nil, key=nil)
      @adapter.set_tls_ssl_context(@client, ca_cert, cert, key)
    end


    ### The following attributes should exists in every MQTT third party librairy.
    ### They are necessary (or really usefull/common) for the establishement of the connection and/or the basic Mqtt actions.
    ### The setter directely change the third party client value when the getter remote the actual SharedClient instance's attribute value
    def host
      @client.host
    end
    
    def host=(host)
      @adapter.set_host(@client, host)
    end

    def port
      @client.port
    end
    
    def port=(port)
      @adapter.set_port(@client, port)
    end

    def ssl
      @client.ssl
    end

    def ssl=(ssl)
      @adapter.set_ssl(@client, ssl)
    end

    #################################################
    ###################### WIP ######################
    #################################################

    def on_test=(on_test)
      @adapter.on_test = on_test
    end
    
    def on_message
      @adapter.on_message = self.on_message
    end
    
    def on_connect
      @adapter.on_connect(client, self.callback)
    end
    
    def on_disconnect
      @adapter.on_disconnect(client, self.callback)
    end

    def on_publish
      @adapter.on_publish(client, self.on_publish )
    end

    def on_subsribe
      @adapter.on_disconnect(client, self.on_subscribe)
    end

    def on_unsubscribe
      @adapter.on_unsubscribe(client, self.on_unsubscribe)
    end
    #################################################
    ###################### WIP ######################
    #################################################
  end
end

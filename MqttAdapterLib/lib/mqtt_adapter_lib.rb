module MqttAdapterLib
  extend self

  ### Return the adapter selected for the module with either a pre-setted value or a default value
  def adapter
    return @adapter if @adapter
    ### Calling the setter method with the default symbol 'ruby_mqtt_adapter' and return it.
    self.adapter = :ruby_mqtt_adapter
    @adapter
  end

  ### The setter of the module's adapter attributes
  def adapter=(adapter_lib)
    case adapter_lib
    when Symbol, String
      begin
        require "adapters/#{adapter_lib}"
      rescue LoadError
        raise "LoadError: Could find adapters for the lib #{adapter_lib}"
        exit
      end
      @adapter = Adapters.const_get("#{adapter_lib.to_s.capitalize}")
    #      @adapter = MqttShareLib::Adapters.const_get("#{adapter_lib.to_s.capitalize}")
    else
      raise "TypeError: Library name should be a String or Symbol"
    end
  end

  class MqttAdapter
    # Restrict access to the base client
    # attr_accessor :client

    attr_reader :client_id
    ### @adapter contains the name of the adapter that should be module as a third party librairy
    ### The method call by the shared client are implemented by the third party or the adapter module itself.
    ### @adapter default value is MqttShareLib::Adapters::Ruby_mqtt_adapter
    attr_accessor :adapter

    ### @on_'event' contains the callback's [block, Proc, lambda] that should be called when 'event' is catched
    ### Callbacks should be define in the upper class (ex. MqqtCore)
    ### Callback shoudl be called by some (private) handlers define in the third party librairy

    ### On instanciation of a SharedClient, the client adapter is set as the previously define module adapter
    ### The client is then initialize with the client type of the third librairy of the adapter.
    ### @client default type is MQTT::Client
    def initialize(*args)
      @adapter = ::MqttAdapterLib.adapter.new(*args)
    end

    def client_id
      @adapter.client_id
    end

    ### The following method represent the basics common MQTT actions.
    ### As possible, they should be implemented in the third party librairy
    ### If not, the adpater should implement them or throw and excpetion
    def connect(*args, &block)
      @adapter.connect(*args, &block)
    end

    def publish(topic, payload='', retain=false, qos=0)
      @adapter.publish(topic, payload, retain, qos)
    end

    def loop_start
      @thread = @adapter.loop_start
    end

    def loop_stop
      @adapter.loop_stop(@thread)
    end

    def loop_forever
      @adapter.loop_forever
    end

    def mqtt_loop
      @adapter.loop
    end

    def loop_read
      @adapter.loop_read
    end

    def loop_write
      @adapter.loop_write
    end

    def loop_misc
      @adapter.loop_misc
    end

    def get(topic=nil, &block)
      @adapter.get(topic, &block)
    end

    def get_packet(topic=nil, &block)
      @adapter.get_packet(topic, &block)
    end

    def generate_client_id
      @adapter.generate_client_id
    end

    def disconnect(send_msg=true)
      @adapter.disconnect(send_msg)
    end

    def connected?
      @adapter.connected?
    end

    def subscribe(topic)
      @adapter.subscribe(topic)
    end

    def unsubscribe(topic)
      @adapter.unsubscribe(topic)
    end

    def set_tls_ssl_context(ca_cert, cert=nil, key=nil)
      @adapter.set_tls_ssl_context(ca_cert, cert, key)
    end


    ### The following attributes should exists in every MQTT third party librairy.
    ### They are necessary (or really usefull and common) for the establishement of the connection and/or the basic Mqtt actions.
    ### The setter directely change the third party client value when the getter remote the actual SharedClient instance's attribute value
    def host
      @adapter.host
    end

    def host=(host)
      @adapter.host = host
    end

    def port
      @adapter.port
    end

    def port=(port)
      @adapter.port = port
    end

    def ssl
      @adapter.ssl
    end

    def ssl=(ssl)
      @adapter.ssl = ssl
    end

    def add_callback_filter_topic(topic, callback)
      @adapter.add_callback_filter_topic(topic, callback)
    end

    def remove_callback_filter_topic(topic)
      @adapter.remove_callback_filter_topic(topic)
    end
    #################################################
    ###################### WIP ######################
    #################################################

    def on_test=(on_test)
      @adapter.on_test = on_test
    end

    def on_message=(callback)
      @adapter.on_message = callback
    end

    #################################################
    ###################### WIP ######################
    #################################################
  end
end

require 'facets'
require 'aws_iot_device/mqtt_adapter/client'

module AwsIotDevice
  module MqttAdapter
    extend self

    ### Return the adapter selected for the module with either a pre-setted value or a default value
    def adapter
      return @adapter if @adapter
      ### Calling the setter method with the default symbol 'RubyMqttAdapter' and return it.
      self.adapter = :paho_mqtt_adapter
      @adapter
    end

    ### The setter of the module's adapter attributes
    def adapter=(adapter_lib)
      case adapter_lib
      when Symbol, String
        begin
          require "aws_iot_device/mqtt_adapter/#{adapter_lib}"
        rescue LoadError
          raise "LoadError: Could find adapters for the lib #{adapter_lib}"
        end
        @adapter = MqttAdapter.const_get("#{adapter_lib.to_s.camelcase(:upper)}")
      else
        raise "TypeError: Library name should be a String or Symbol"
      end
    end
  end
end

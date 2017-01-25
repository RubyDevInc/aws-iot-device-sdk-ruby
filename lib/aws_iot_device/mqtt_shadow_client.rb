require 'aws_iot_device/mqtt_shadow_client/shadow_client'

module AwsIotDevice
  module MqttShadowClient
    ACTION_NAME = %w(get update delete delta).freeze
  end
end

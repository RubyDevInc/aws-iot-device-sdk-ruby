# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_iot_device/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_iot_device"
  spec.version       = AwsIotDevice::VERSION
  spec.authors       = ["Pierre Goudet"]
  spec.email         = ["p-goudet@ruby-dev.jp"]

  spec.summary       = %q{The ruby version of the AWS IoT Device SDK. It enables to connect to AWS IoT platform and manage Things.}
  spec.description   = %q{The gem is using the MQTT protocol to execute the command defined by the AWS IoT platform. A default MQTT client is included in the gem, however an adapter system enables to plug another MQTT client.}
  spec.homepage      = "https://github.com/RubyDevInc/aws-iot-device-sdk-ruby"
  spec.license       = "Apache-2.0"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10", ">= 1.10"
  spec.add_development_dependency "pry", "~> 0.10.4", ">= 0.10.4"
  spec.add_development_dependency "rake", "~> 10.0", ">= 1.10" 
  spec.add_development_dependency "rspec", "~> 3.5.0", ">= 3.5.0"

  spec.add_runtime_dependency "facets", "~> 3.1.0", ">= 3.1.0"
  spec.add_runtime_dependency "json", "~> 2.0.2", ">= 2.0.2"
  #spec.add_runtime_dependency "paho-mqtt", "~> 1.0.0", ">= 1.0.0"
  spec.add_runtime_dependency "timers", "~> 4.1.1", ">= 4.1.1"
end

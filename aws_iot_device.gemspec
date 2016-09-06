# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_iot_device/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_iot_device"
  spec.version       = AwsIotDevice::VERSION
  spec.authors       = ["Pierre Goudet"]
  spec.email         = ["p-goudet@ruby-dev.jp"]

  spec.summary       = %q{A gem use to communicates with the Aws Iot platform through the MQTT protocol}
  spec.description   = %q{A gem use to communicates with the Aws Iot platform through the MQTT protocol}
  spec.homepage      = "https://github.com/RubyDevInc/aws-iot-device-sdk-ruby"
  spec.license       = "Apache 2.0"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "facets", "~> 3.0.0"
  spec.add_runtime_dependency "json", "~> 1.8.3"
  spec.add_runtime_dependency "mqtt", "~> 0.4.0"
  spec.add_runtime_dependency "timers", "~> 4.1.1"
end

require 'bundler/setup'
require 'absmartly/liquid'
require 'webmock/rspec'
require 'simplecov'
require 'ostruct'

# Ruby SDK is already loaded via absmartly/liquid which requires 'absmartly'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

SimpleCov.start do
  add_filter '/spec/'
end

# Test event collector - similar to cross-sdk-tests pattern
class TestEventCollector
  attr_reader :events

  def initialize
    @events = []
  end

  def handle_event(event_type, data)
    @events << {
      type: event_type.to_s,
      data: data,
      timestamp: (Time.now.to_f * 1000).to_i
    }
  end
end

# Custom event handler that doesn't make HTTP calls
class TestEventHandler < ContextEventHandler
  def initialize(event_collector)
    @event_collector = event_collector
  end

  def publish(context, event)
    @event_collector.handle_event(:publish, event)
    self
  end
end

# Data wrapper for test data
class TestDataWrapper
  attr_reader :data_future

  def initialize(data)
    @data_future = hash_to_ostruct(data)
  end

  def success?
    true
  end

  def exception
    nil
  end

  private

  def hash_to_ostruct(obj)
    return obj unless obj.is_a?(Hash)

    obj.each_with_object(OpenStruct.new) do |(key, val), ostruct|
      snake_key = camel_to_snake(key.to_s)
      ostruct[snake_key] = if val.is_a?(Hash)
                             hash_to_ostruct(val)
                           elsif val.is_a?(Array)
                             val.map { |v| v.is_a?(Hash) ? hash_to_ostruct(v) : v }
                           else
                             val
                           end
    end
  end

  def camel_to_snake(str)
    str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .downcase
  end
end

# Helper method to create a test context
def create_test_context(units:, data:, event_collector: nil)
  event_collector ||= TestEventCollector.new
  test_event_handler = TestEventHandler.new(event_collector)

  client_config = ClientConfig.new
  client_config.endpoint = 'http://test'
  client_config.api_key = 'test-key'
  client_config.application = 'test'
  client_config.environment = 'test'

  client = Client.new(client_config, nil)

  sdk_config = ABSmartlyConfig.new
  sdk_config.client = client
  sdk_config.context_event_handler = test_event_handler
  sdk_config.context_event_logger = event_collector

  sdk = ABSmartly.new(sdk_config)

  context_config = ContextConfig.new
  context_config.units = units
  context_config.publish_delay = -1
  context_config.refresh_interval = 0

  data_wrapper = TestDataWrapper.new(data)
  sdk.create_context_with(context_config, data_wrapper)
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed
end

require_relative 'logging'

module ABsmartly
  module Liquid
    class Drop < ::Liquid::Drop
      include ABsmartly::Liquid::Logging
      attr_reader :absmartly_context

      def initialize(absmartly_context)
        super()
        @absmartly_context = absmartly_context
      end

      def ready
        @absmartly_context.ready?
      rescue StandardError => e
        log_error("Error checking ready state: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        false
      end

      alias ready? ready

      def failed
        @absmartly_context.failed?
      rescue StandardError => e
        log_error("Error checking failed state: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        false
      end

      def closed
        @absmartly_context.closed?
      rescue StandardError => e
        log_error("Error checking closed state: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        false
      end

      alias finalized closed

      def experiments
        @absmartly_context.experiments
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("Error retrieving experiments: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        []
      end

      def pending
        @absmartly_context.pending_count
      rescue StandardError => e
        log_error("Error retrieving pending count: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def treatment(experiment_name)
        validate_non_empty_string(experiment_name, 'Experiment name')
        @absmartly_context.treatment(experiment_name)
      rescue StandardError => e
        raise if sdk_not_ready? || sdk_state_error?(e)
        log_error("Error in treatment for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def peek(experiment_name)
        validate_non_empty_string(experiment_name, 'Experiment name')
        @absmartly_context.peek_treatment(experiment_name)
      rescue StandardError => e
        raise if sdk_not_ready? || sdk_state_error?(e)
        log_error("Error in peek for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def variable(key, default_value)
        validate_non_empty_string(key, 'Variable key')
        @absmartly_context.variable_value(key, default_value)
      rescue StandardError => e
        raise if sdk_not_ready? || sdk_state_error?(e)
        log_error("Error in variable for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def peek_variable(key, default_value)
        validate_non_empty_string(key, 'Variable key')
        @absmartly_context.peek_variable_value(key, default_value)
      rescue StandardError => e
        raise if sdk_not_ready? || sdk_state_error?(e)
        log_error("Error in peek_variable for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def custom_field(experiment_name, field_name)
        validate_non_empty_string(experiment_name, 'Experiment name')
        validate_non_empty_string(field_name, 'Field name')
        @absmartly_context.custom_field_value(experiment_name, field_name)
      rescue StandardError => e
        raise if sdk_not_ready? || sdk_state_error?(e)
        log_error("Error in custom_field for '#{experiment_name}.#{field_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        nil
      end

      # Errors raised by the SDK's track (finalized context, invalid goal
      # properties) always propagate: a swallowed goal would be lost silently.
      # Only an invalid goal name supplied by the template falls back to nil.
      def track(goal_name, properties = nil)
        begin
          validate_non_empty_string(goal_name, 'Goal name')
        rescue ArgumentError => e
          log_error("Error in track for '#{goal_name}': #{e.message}")
          raise if ABsmartly::Liquid.strict_mode
          return nil
        end
        @absmartly_context.track(goal_name, properties)
      end

      def data
        @absmartly_context.data
      rescue StandardError => e
        log_error("Error retrieving context data: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        {}
      end

      def units
        @absmartly_context.units.dup
      rescue StandardError => e
        log_error("Error retrieving units: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        {}
      end

      private

      # SDK reads on a context that is not yet ready raise the SDK's not-ready
      # error; it is raised in every mode (matching the JS SDK), not replaced
      # by a fallback.
      def sdk_not_ready?
        @absmartly_context.respond_to?(:ready?) && !@absmartly_context.ready?
      rescue StandardError
        false
      end

      # The SDK's lifecycle errors (not yet ready, finalized) are raised in
      # every mode, matching the JS SDK, rather than replaced by a fallback.
      def sdk_state_error?(error)
        defined?(::IllegalStateException) && error.is_a?(::IllegalStateException)
      end

      def validate_non_empty_string(value, label)
        return if value.is_a?(String) && !value.empty?

        raise ArgumentError, "#{label} must be a non-empty string"
      end
    end
  end
end

module ABsmartly
  module Liquid
    class Drop < ::Liquid::Drop
      attr_reader :absmartly_context

      def initialize(absmartly_context)
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
        validate_experiment_name(experiment_name)
        @absmartly_context.treatment(experiment_name)
      rescue StandardError => e
        log_error("Error in treatment for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def peek(experiment_name)
        validate_experiment_name(experiment_name)
        @absmartly_context.peek_treatment(experiment_name)
      rescue StandardError => e
        log_error("Error in peek for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def variable(key, default_value)
        validate_variable_key(key)
        @absmartly_context.variable_value(key, default_value)
      rescue StandardError => e
        log_error("Error in variable for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def peek_variable(key, default_value)
        validate_variable_key(key)
        @absmartly_context.peek_variable_value(key, default_value)
      rescue StandardError => e
        log_error("Error in peek_variable for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def custom_field(experiment_name, field_name)
        validate_experiment_name(experiment_name)
        validate_field_name(field_name)
        @absmartly_context.custom_field_value(experiment_name, field_name)
      rescue StandardError => e
        log_error("Error in custom_field for '#{experiment_name}.#{field_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        nil
      end

      def track(goal_name, properties = nil)
        validate_goal_name(goal_name)
        result = @absmartly_context.track(goal_name, properties)
        result
      rescue StandardError => e
        log_error("Error in track for '#{goal_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        nil
      end

      def data
        @absmartly_context.data
      rescue StandardError => e
        log_error("Error retrieving context data: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        {}
      end

      def units
        sanitized_units = @absmartly_context.units.dup
        sanitized_units
      rescue StandardError => e
        log_error("Error retrieving units: #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        {}
      end

      private

      def validate_experiment_name(name)
        return if name.is_a?(String) && !name.empty?

        raise ArgumentError, 'Experiment name must be a non-empty string'
      end

      def validate_variable_key(key)
        return if key.is_a?(String) && !key.empty?

        raise ArgumentError, 'Variable key must be a non-empty string'
      end

      def validate_field_name(name)
        return if name.is_a?(String) && !name.empty?

        raise ArgumentError, 'Field name must be a non-empty string'
      end

      def validate_goal_name(name)
        return if name.is_a?(String) && !name.empty?

        raise ArgumentError, 'Goal name must be a non-empty string'
      end

      def log_error(message)
        ABsmartly::Liquid.logger&.error("[ABsmartly Liquid SDK] #{message}")
      end
    end
  end
end

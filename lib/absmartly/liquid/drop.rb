module ABsmartly
  module Liquid
    class Drop < ::Liquid::Drop
      def initialize(absmartly_context)
        @absmartly_context = absmartly_context
      end

      def ready
        @absmartly_context.ready?
      end

      def failed
        @absmartly_context.failed?
      end

      def closed
        @absmartly_context.closed?
      end

      alias finalized closed

      def experiments
        @absmartly_context.experiments
      end

      def pending
        @absmartly_context.pending_count
      end

      def treatment(experiment_name)
        @absmartly_context.treatment(experiment_name)
      end

      def peek(experiment_name)
        @absmartly_context.peek_treatment(experiment_name)
      end

      def variable(key, default_value)
        @absmartly_context.variable_value(key, default_value)
      end

      def peek_variable(key, default_value)
        @absmartly_context.peek_variable_value(key, default_value)
      end

      def custom_field(experiment_name, field_name)
        @absmartly_context.custom_field_value(experiment_name, field_name)
      end

      def track(goal_name, properties = nil)
        @absmartly_context.track(goal_name, properties)
        nil
      end

      def data
        @absmartly_context.data
      end

      def units
        @absmartly_context.units
      end

      # Allow filters to access the underlying context
      def absmartly_context
        @absmartly_context
      end
    end
  end
end

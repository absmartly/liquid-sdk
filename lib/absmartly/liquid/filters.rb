module ABsmartly
  module Liquid
    module Filters
      def absmartly_treatment(experiment_name)
        context = get_absmartly_context
        return 0 unless context && context.ready?

        context.treatment(experiment_name)
      end

      def absmartly_peek(experiment_name)
        context = get_absmartly_context
        return 0 unless context && context.ready?

        context.peek_treatment(experiment_name)
      end

      def absmartly_variable(key, default_value)
        context = get_absmartly_context
        return default_value unless context && context.ready?

        context.variable_value(key, default_value)
      end

      def absmartly_peek_variable(key, default_value)
        context = get_absmartly_context
        return default_value unless context && context.ready?

        context.peek_variable_value(key, default_value)
      end

      def absmartly_custom_field(experiment_name, field_name)
        context = get_absmartly_context
        return nil unless context && context.ready?

        context.custom_field_value(experiment_name, field_name)
      end

      def absmartly_track(goal_name, properties = {})
        context = get_absmartly_context
        return '' unless context

        context.track(goal_name, properties)
        ''
      end

      private

      def get_absmartly_context
        @context['absmartly']&.absmartly_context ||
          ABsmartly::Liquid.current_context
      end
    end
  end
end

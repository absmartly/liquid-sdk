require_relative 'logging'

module ABsmartly
  module Liquid
    module Filters
      include ABsmartly::Liquid::Logging
      def absmartly_treatment(experiment_name)
        with_ready_context(0) do |ctx|
          ctx.treatment(experiment_name)
        end
      rescue StandardError => e
        log_error("ABsmartly treatment error for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def absmartly_peek(experiment_name)
        with_ready_context(0) do |ctx|
          ctx.peek_treatment(experiment_name)
        end
      rescue StandardError => e
        log_error("ABsmartly peek error for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def absmartly_variable(key, default_value)
        with_ready_context(default_value) do |ctx|
          ctx.variable_value(key, default_value)
        end
      rescue StandardError => e
        log_error("ABsmartly variable error for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def absmartly_peek_variable(key, default_value)
        with_ready_context(default_value) do |ctx|
          ctx.peek_variable_value(key, default_value)
        end
      rescue StandardError => e
        log_error("ABsmartly peek_variable error for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def absmartly_custom_field(experiment_name, field_name)
        with_ready_context(nil) do |ctx|
          ctx.custom_field_value(experiment_name, field_name)
        end
      rescue StandardError => e
        log_error("ABsmartly custom_field error for '#{experiment_name}.#{field_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        nil
      end

      def absmartly_track(goal_name, properties = {})
        with_ready_context('') do |ctx|
          ctx.track(goal_name, properties)
          ''
        end
      rescue StandardError => e
        log_error("ABsmartly track error for '#{goal_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        ''
      end

      private

      def with_ready_context(fallback)
        context = get_absmartly_context

        unless context
          log_warning('ABsmartly context missing, returning fallback value')
          raise 'ABsmartly context not available' if ABsmartly::Liquid.strict_mode
          return fallback
        end

        unless context.ready?
          log_warning('ABsmartly context not ready, returning fallback value')
          raise 'ABsmartly context not ready' if ABsmartly::Liquid.strict_mode
          return fallback
        end

        yield context
      end

      def get_absmartly_context
        return nil unless @context

        drop = @context['absmartly']
        return nil unless drop

        drop.respond_to?(:absmartly_context) ? drop.absmartly_context : nil
      end
    end
  end
end

require_relative 'logging'

module ABsmartly
  module Liquid
    module Filters
      include ABsmartly::Liquid::Logging

      # Wraps the SDK error raised by a read on a context that is not yet ready.
      # It carries the SDK's message and is never converted into a fallback.
      class NotReadyError < StandardError
        attr_reader :cause_error

        def initialize(error)
          @cause_error = error
          super(error.message)
        end
      end
      def absmartly_treatment(experiment_name)
        with_ready_context(0) do |ctx|
          ctx.treatment(experiment_name)
        end
      rescue NotReadyError => e
        raise e.cause_error
      rescue ContextUnavailableError
        raise
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("ABsmartly treatment error for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def absmartly_peek(experiment_name)
        with_ready_context(0) do |ctx|
          ctx.peek_treatment(experiment_name)
        end
      rescue NotReadyError => e
        raise e.cause_error
      rescue ContextUnavailableError
        raise
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("ABsmartly peek error for '#{experiment_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        0
      end

      def absmartly_variable(key, default_value)
        with_ready_context(default_value) do |ctx|
          ctx.variable_value(key, default_value)
        end
      rescue NotReadyError => e
        raise e.cause_error
      rescue ContextUnavailableError
        raise
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("ABsmartly variable error for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def absmartly_peek_variable(key, default_value)
        with_ready_context(default_value) do |ctx|
          ctx.peek_variable_value(key, default_value)
        end
      rescue NotReadyError => e
        raise e.cause_error
      rescue ContextUnavailableError
        raise
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("ABsmartly peek_variable error for '#{key}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        default_value
      end

      def absmartly_custom_field(experiment_name, field_name)
        with_ready_context(nil) do |ctx|
          ctx.custom_field_value(experiment_name, field_name)
        end
      rescue NotReadyError => e
        raise e.cause_error
      rescue ContextUnavailableError
        raise
      rescue StandardError => e
        raise if sdk_state_error?(e)
        log_error("ABsmartly custom_field error for '#{experiment_name}.#{field_name}': #{e.message}")
        raise if ABsmartly::Liquid.strict_mode
        nil
      end

      def absmartly_track(goal_name, properties = {})
        # JS track() only checks "not finalized", never "ready": events tracked
        # before the context is ready are queued by the SDK, so do not gate on ready?.
        ctx = get_absmartly_context
        unless ctx
          log_warning("ABsmartly context missing, event '#{goal_name}' dropped")
          raise ContextUnavailableError if ABsmartly::Liquid.strict_mode
          return ''
        end
        # Errors raised by the SDK's track (finalized context, invalid goal
        # properties) propagate in every mode: a swallowed goal is lost silently.
        ctx.track(goal_name, properties)
        ''
      end

      private

      def sdk_state_error?(error)
        defined?(::IllegalStateException) && error.is_a?(::IllegalStateException)
      end

      def with_ready_context(fallback)
        context = get_absmartly_context

        unless context
          log_warning('ABsmartly context missing, returning fallback value')
          raise ContextUnavailableError if ABsmartly::Liquid.strict_mode
          return fallback
        end

        # Reads before the context is ready raise the SDK's own not-ready error
        # in every mode (matching the JS SDK); it is not turned into a fallback.
        unless context.ready?
          begin
            return yield context
          rescue StandardError => e
            raise NotReadyError.new(e)
          end
        end

        yield context
      end

      def get_absmartly_context
        if @context
          drop = @context['absmartly']
          if drop
            ctx = drop.respond_to?(:absmartly_context) ? drop.absmartly_context : nil
            return ctx if ctx
          end
        end

        ABsmartly::Liquid.current_context
      end
    end
  end
end

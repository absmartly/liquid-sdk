require_relative 'logging'

module ABsmartly
  module Liquid
    module Tags
      class TreatmentTag < ::Liquid::Block
        include ABsmartly::Liquid::Logging
        def initialize(tag_name, markup, options)
          super

          markup_trimmed = markup.strip
          if markup_trimmed.empty?
            raise ::Liquid::SyntaxError, "Syntax Error in 'absmartly_treatment' - Valid syntax: {% absmartly_treatment 'experiment_name' %}. Experiment names may contain letters, numbers, underscores, hyphens, and dots."
          end

          @experiment_name = ::Liquid::Expression.parse(markup_trimmed)
        end

        def render(context)
          experiment_name = context.evaluate(@experiment_name)
          absmartly = context['absmartly']

          variant = if absmartly && not_ready?(absmartly)
            # Not ready: the SDK raises its own not-ready error, which is
            # raised in every mode (matching the JS SDK) rather than rendering control.
            absmartly.treatment(experiment_name)
          elsif absmartly
            begin
              absmartly.treatment(experiment_name)
            rescue StandardError => e
              # Lifecycle errors (finalized) are raised in every mode.
              raise if defined?(::IllegalStateException) && e.is_a?(::IllegalStateException)
              log_error("Treatment error for '#{experiment_name}': #{e.message}")
              raise if ABsmartly::Liquid.strict_mode
              0
            end
          else
            log_warning("ABsmartly context missing for treatment '#{experiment_name}', returning control variant")
            raise ContextUnavailableError if ABsmartly::Liquid.strict_mode
            0
          end

          context.stack do
            context['variant'] = variant
            super
          end
        end

        private

        def not_ready?(absmartly)
          absmartly.respond_to?(:ready?) && !absmartly.ready?
        rescue StandardError => e
          log_error("ABsmartly readiness error: #{e.message}")
          raise if ABsmartly::Liquid.strict_mode
          false
        end

      end

      class TrackTag < ::Liquid::Tag
        include ABsmartly::Liquid::Logging
        def initialize(tag_name, markup, options)
          super

          markup_trimmed = markup.strip
          if markup_trimmed.empty?
            raise ::Liquid::SyntaxError, "Syntax Error in 'absmartly_track' - Valid syntax: {% absmartly_track 'goal_name', key: value %}. Goal names may contain letters, numbers, underscores, hyphens, and dots."
          end

          parts = markup_trimmed.split(',', 2)
          @goal_name = ::Liquid::Expression.parse(parts[0].strip)
          @properties_markup = parts[1]&.strip
        end

        def render(context)
          goal_name = context.evaluate(@goal_name)
          properties = parse_properties(context)

          absmartly = context['absmartly']

          # No ready? gate: JS track() queues events before the context is ready.
          # SDK track errors (finalized, invalid properties) propagate.
          if absmartly
            absmartly.track(goal_name, properties)
          else
            log_warning("ABsmartly context missing, event '#{goal_name}' dropped")
            raise ContextUnavailableError if ABsmartly::Liquid.strict_mode
          end

          ''
        end

        private

        def parse_properties(context)
          return {} unless @properties_markup

          properties = @properties_markup.scan(/([\w\-\.]+):\s*((?:'[^']*'|"[^"]*"|[^,])+)/).to_h do |key, value|
            evaluated = context.evaluate(value.strip)
            [key, evaluated]
          end

          if properties.empty? && !@properties_markup.strip.empty?
            log_warning("Failed to parse track properties: '#{@properties_markup}'")
          end

          properties
        end

      end
    end
  end
end

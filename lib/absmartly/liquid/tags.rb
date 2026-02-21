module ABsmartly
  module Liquid
    module Tags
      class TreatmentTag < ::Liquid::Block
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

          variant = if absmartly && absmartly.respond_to?(:ready?) && absmartly.ready?
            begin
              absmartly.treatment(experiment_name)
            rescue StandardError => e
              log_error("Treatment error for '#{experiment_name}': #{e.message}")
              raise if ABsmartly::Liquid.strict_mode
              0
            end
          else
            log_warning("ABsmartly context missing or not ready for treatment '#{experiment_name}', returning control variant")
            raise 'ABsmartly context not available or not ready' if ABsmartly::Liquid.strict_mode
            0
          end

          context.stack do
            context['variant'] = variant
            super
          end
        end

        private

        def log_warning(message)
          ABsmartly::Liquid.logger&.warn("[ABsmartly Liquid SDK] #{message}")
        end

        def log_error(message)
          ABsmartly::Liquid.logger&.error("[ABsmartly Liquid SDK] #{message}")
        end
      end

      class TrackTag < ::Liquid::Tag
        def initialize(tag_name, markup, options)
          super

          markup_trimmed = markup.strip
          if markup_trimmed.empty?
            raise ::Liquid::SyntaxError, "Syntax Error in 'absmartly_track' - Valid syntax: {% absmartly_track 'goal_name', key: value %}. Goal names may contain letters, numbers, underscores, hyphens, and dots."
          end

          # Split by comma to separate goal name from properties
          parts = markup_trimmed.split(',', 2)
          @goal_name = ::Liquid::Expression.parse(parts[0].strip)
          @properties_markup = parts[1]&.strip
        end

        def render(context)
          goal_name = context.evaluate(@goal_name)
          properties = parse_properties(context)

          absmartly = context['absmartly']

          if absmartly && absmartly.respond_to?(:ready?) && absmartly.ready?
            begin
              absmartly.track(goal_name, properties)
            rescue StandardError => e
              log_error("Track error for '#{goal_name}': #{e.message}")
              raise if ABsmartly::Liquid.strict_mode
            end
          else
            log_warning("ABsmartly context missing or not ready, event '#{goal_name}' dropped")
            raise 'ABsmartly context not available or not ready' if ABsmartly::Liquid.strict_mode
          end

          ''
        end

        private

        def parse_properties(context)
          return {} unless @properties_markup

          properties = @properties_markup.scan(/([\w\-\.]+):\s*([^,]+)/).to_h do |key, value|
            evaluated = context.evaluate(value.strip)
            [key, evaluated]
          end

          if properties.empty? && !@properties_markup.strip.empty?
            log_warning("Failed to parse track properties: '#{@properties_markup}'")
          end

          properties
        end

        def log_warning(message)
          ABsmartly::Liquid.logger&.warn("[ABsmartly Liquid SDK] #{message}")
        end

        def log_error(message)
          ABsmartly::Liquid.logger&.error("[ABsmartly Liquid SDK] #{message}")
        end
      end
    end
  end
end

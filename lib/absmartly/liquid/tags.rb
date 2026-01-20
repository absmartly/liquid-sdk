module ABsmartly
  module Liquid
    module Tags
      class TreatmentTag < ::Liquid::Block
        Syntax = /(\w+)/

        def initialize(tag_name, markup, options)
          super

          if markup =~ Syntax
            @experiment_name = ::Liquid::Expression.parse($1)
          else
            raise ::Liquid::SyntaxError, "Syntax Error in 'absmartly_treatment' - Valid syntax: {% absmartly_treatment 'experiment_name' %}"
          end
        end

        def render(context)
          experiment_name = context.evaluate(@experiment_name)
          absmartly = context['absmartly']

          variant = if absmartly && absmartly.respond_to?(:treatment)
            absmartly.treatment(experiment_name)
          else
            0
          end

          context.stack do
            context['variant'] = variant
            super
          end
        end
      end

      class TrackTag < ::Liquid::Tag
        Syntax = /(\w+)(?:,\s*(.+))?/

        def initialize(tag_name, markup, options)
          super

          if markup =~ Syntax
            @goal_name = ::Liquid::Expression.parse($1)
            @properties_markup = $2
          else
            raise ::Liquid::SyntaxError, "Syntax Error in 'absmartly_track' - Valid syntax: {% absmartly_track 'goal_name', key: value %}"
          end
        end

        def render(context)
          goal_name = context.evaluate(@goal_name)
          properties = parse_properties(context)

          absmartly = context['absmartly']
          absmartly.track(goal_name, properties) if absmartly && absmartly.respond_to?(:track)

          ''
        end

        private

        def parse_properties(context)
          return {} unless @properties_markup

          properties = {}
          @properties_markup.scan(/(\w+):\s*([^,]+)/) do |key, value|
            properties[key] = context.evaluate(value)
          end
          properties
        end
      end
    end
  end
end

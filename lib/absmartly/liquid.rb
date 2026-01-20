require 'liquid'
require 'absmartly'

module ABsmartly
  module Liquid
    autoload :Drop, 'absmartly/liquid/drop'
    autoload :Filters, 'absmartly/liquid/filters'
    autoload :Tags, 'absmartly/liquid/tags'

    class << self
      attr_accessor :current_context

      def register_filters
        ::Liquid::Template.register_filter(Filters)
      end

      def register_tags
        ::Liquid::Template.register_tag('absmartly_treatment', Tags::TreatmentTag)
        ::Liquid::Template.register_tag('absmartly_track', Tags::TrackTag)
      end

      def register_all
        register_filters
        register_tags
      end
    end
  end
end

ABsmartly::Liquid.register_all

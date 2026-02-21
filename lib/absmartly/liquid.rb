require 'liquid'
require 'absmartly'

require 'logger'

module ABsmartly
  module Liquid
    autoload :Drop, 'absmartly/liquid/drop'
    autoload :Filters, 'absmartly/liquid/filters'
    autoload :Tags, 'absmartly/liquid/tags'

    class << self
      attr_accessor :logger
      attr_accessor :strict_mode

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

    self.logger = Logger.new($stdout)
    self.logger.level = Logger::WARN
    self.strict_mode = false
  end
end

ABsmartly::Liquid.register_all

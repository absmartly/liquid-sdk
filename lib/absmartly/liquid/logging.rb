module ABsmartly
  module Liquid
    module Logging
      private

      def log_warning(message)
        ABsmartly::Liquid.logger&.warn("[ABsmartly Liquid SDK] #{message}")
      end

      def log_error(message)
        ABsmartly::Liquid.logger&.error("[ABsmartly Liquid SDK] #{message}")
      end
    end
  end
end

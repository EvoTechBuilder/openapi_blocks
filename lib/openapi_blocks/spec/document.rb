# frozen_string_literal: true

require_relative "components"
require_relative "paths"

module OpenapiBlocks
  module Spec
    class Document # rubocop:disable Style/Documentation
      def initialize(openapi_classes)
        @openapi_classes = openapi_classes
      end

      def build
        config = OpenapiBlocks.configuration

        {
          openapi:    config.openapi_version == "3.1" ? "3.1.0" : "3.0.3",
          info:       config.info.to_h,
          servers:    config.to_h[:servers],
          paths:      Paths.new.build,
          components: Components.new(@openapi_classes).build
        }
      end
    end
  end
end

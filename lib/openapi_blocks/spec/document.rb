# frozen_string_literal: true

require_relative "components"
require_relative "paths"

module OpenapiBlocks
  module Spec
    class Document # rubocop:disable Style/Documentation
      def initialize(openapi_classes)
        @openapi_classes = openapi_classes
      end

      def build # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        config     = OpenapiBlocks.configuration
        components = Components.new(@openapi_classes).build
        security   = config.security

        components[:securitySchemes] = security.to_h if security&.schemes&.any?

        doc = {
          openapi:    config.openapi_version,
          info:       config.info.to_h,
          servers:    config.to_h[:servers],
          paths:      Paths.new.build,
          components: components
        }

        doc[:security] = security.schemes.keys.map { |s| { s => [] } } if security&.schemes&.any?

        doc
      end
    end
  end
end

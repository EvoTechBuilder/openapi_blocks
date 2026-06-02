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

        paths = Paths.new.build

        doc = {
          openapi:    config.openapi_version,
          info:       config.info.to_h,
          servers:    config.to_h[:servers],
          paths:      paths,
          components: components,
          tags:       build_tags_from_paths(paths)
        }

        doc[:security] = security.schemes.keys.map { |s| { s => [] } } if security&.schemes&.any?

        doc
      end

      private

      def build_tags_from_paths(paths)
        names = paths.values.flat_map do |operations|
          operations.values.flat_map { |op| Array(op[:tags]) }
        end

        names.uniq.map { |n| { name: n } }
      end
    end
  end
end

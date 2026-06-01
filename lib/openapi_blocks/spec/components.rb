# frozen_string_literal: true

require_relative "../schema/extractor"
require_relative "../schema/validator"

module OpenapiBlocks
  module Spec
    class Components # rubocop:disable Style/Documentation
      def initialize(openapi_classes)
        @openapi_classes = openapi_classes
      end

      def build
        schemas = @openapi_classes.each_with_object({}) do |klass, hash|
          schema_name = klass.model.name
          extractor   = Schema::Extractor.new(klass)
          validator   = Schema::Validator.new(klass.model)

          schema = extractor.extract
          schema[:properties] = merge_validations(schema[:properties], validator.extract)

          hash[schema_name] = schema
        end

        { schemas: schemas }
      end

      private

      def merge_validations(properties, validations)
        return properties if properties.blank?

        properties.each_with_object({}) do |(name, schema), hash|
          hash[name] = schema.merge(validations.fetch(name, {}))
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../schema/extractor"
require_relative "../schema/validator"

module OpenapiBlocks
  module Spec
    class Components # rubocop:disable Style/Documentation
      INPUT_IGNORED_PROPERTIES = %w[id created_at updated_at deleted_at].freeze

      def initialize(openapi_classes)
        @openapi_classes = openapi_classes
      end

      def build # rubocop:disable Metrics/AbcSize
        schemas = @openapi_classes.each_with_object({}) do |klass, hash|
          schema_name = klass.model.name
          extractor   = Schema::Extractor.new(klass)
          validator   = Schema::Validator.new(klass.model)

          schema              = extractor.extract
          schema[:properties] = merge_validations(schema[:properties], validator.extract)

          hash[schema_name]            = schema
          hash["#{schema_name}Input"]  = build_input(schema, klass)
        end

        { schemas: schemas }
      end

      private

      def build_input(schema, openapi_class) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        read_only_virtuals = Array(openapi_class._virtual_attributes)
                             .select { |attr| attr[:read_only] == true }
                             .map { |attr| attr[:name].to_s }

        read_only_associations = Array(openapi_class._associations)
                                 .select { |assoc| assoc[:read_only] == true }
                                 .map { |assoc| assoc[:name].to_s }

        input_properties = schema[:properties].reject do |name, property|
          INPUT_IGNORED_PROPERTIES.include?(name.to_s) ||
            read_only_virtuals.include?(name.to_s)      ||
            read_only_associations.include?(name.to_s)  ||
            property[:readOnly] == true
        end

        {
          type:       "object",
          required:   filter_required(schema[:required], input_properties),
          properties: input_properties
        }.compact
      end

      def filter_required(required, input_properties)
        return nil if required.blank?

        filtered = required.select { |r| input_properties.key?(r) || input_properties.key?(r.to_sym) }
        filtered.empty? ? nil : filtered
      end

      def merge_validations(properties, validations)
        return properties if properties.blank?

        properties.each_with_object({}) do |(name, schema), hash|
          hash[name] = schema.merge(validations.fetch(name, {}))
        end
      end
    end
  end
end

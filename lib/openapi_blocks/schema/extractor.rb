# frozen_string_literal: true

require_relative "types"

module OpenapiBlocks
  module Schema
    class Extractor # rubocop:disable Style/Documentation
      IGNORED_COLUMNS = %w[
        password_digest
        encrypted_password
        reset_password_token
        reset_password_sent_at
        remember_created_at
        confirmation_token
        confirmed_at
        confirmation_sent_at
        unconfirmed_email
        failed_attempts
        unlock_token
        locked_at
      ].freeze

      def initialize(openapi_class)
        @openapi_class = openapi_class
        @model         = openapi_class.model
        @ignored       = Array(openapi_class._ignored) + IGNORED_COLUMNS
      end

      def extract
        properties = {}

        column_properties.each      { |name, schema| properties[name] = schema }
        virtual_properties.each     { |name, schema| properties[name] = schema }
        association_properties.each { |name, schema| properties[name] = schema }

        {
          type:       "object",
          required:   required_columns,
          properties: properties
        }.compact
      end

      private

      def column_properties
        @model.columns.each_with_object({}) do |column, hash|
          next if @ignored.include?(column.name)

          hash[column.name] = Types.map(column.sql_type_metadata.type)
        end
      end

      def virtual_properties
        Array(@openapi_class._virtual_attributes).each_with_object({}) do |attr, hash|
          name    = attr.delete(:name)
          options = attr

          hash[name.to_s] = build_virtual_property(options)
        end
      end

      def association_properties
        Array(@openapi_class._associations).each_with_object({}) do |assoc, hash|
          name      = assoc[:name]
          type      = assoc[:type]
          input     = assoc.fetch(:input, true)
          ref       = { "$ref" => "#/components/schemas/#{name.to_s.classify}" }

          schema = type == :array ? { type: "array", items: ref } : ref
          schema[:readOnly] = true unless input

          hash[name.to_s] = schema
        end
      end

      def required_columns # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        association_names = Array(@openapi_class._associations).map { |a| a[:name].to_s }

        required = @model.validators.each_with_object([]) do |validator, arr|
          next unless validator.is_a?(ActiveModel::Validations::PresenceValidator)

          validator.attributes.each do |attr|
            next if @ignored.include?(attr.to_s)
            next if association_names.include?(attr.to_s)

            arr << attr.to_s
          end
        end

        required.empty? ? nil : required
      end

      def build_virtual_property(options)
        property = {}
        property[:type]        = options[:type].to_s      if options[:type]
        property[:format]      = options[:format].to_s    if options[:format]
        property[:description] = options[:description]    if options[:description]
        property[:readOnly]    = options[:read_only]      if options[:read_only]
        property
      end
    end
  end
end

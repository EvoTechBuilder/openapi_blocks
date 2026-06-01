# frozen_string_literal: true

module OpenapiBlocks
  module Schema
    class Validator # rubocop:disable Style/Documentation
      def initialize(model)
        @model = model
      end

      def extract
        @model.validators.each_with_object({}) do |validator, hash|
          validator.attributes.each do |attribute|
            hash[attribute.to_s] ||= {}
            hash[attribute.to_s].merge!(convert(validator))
          end
        end
      end

      private

      def convert(validator) # rubocop:disable Metrics/MethodLength
        case validator
        in ActiveModel::Validations::LengthValidator
          convert_length(validator)
        in ActiveModel::Validations::NumericalityValidator
          convert_numericality(validator)
        in ActiveModel::Validations::InclusionValidator
          convert_inclusion(validator)
        in ActiveModel::Validations::FormatValidator
          convert_format(validator)
        else
          {}
        end
      end

      def convert_length(validator)
        options = validator.options
        result  = {}

        result[:minLength] = options[:minimum] if options[:minimum]
        result[:maxLength] = options[:maximum] if options[:maximum]
        result[:minLength] = options[:is]      if options[:is]
        result[:maxLength] = options[:is]      if options[:is]

        result
      end

      def convert_numericality(validator) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
        options = validator.options
        result  = {}

        result[:minimum]          = options[:greater_than] + 1 if options[:greater_than]
        result[:minimum]          = options[:greater_than_or_equal_to] if options[:greater_than_or_equal_to]
        result[:maximum]          = options[:less_than] - 1 if options[:less_than]
        result[:maximum]          = options[:less_than_or_equal_to] if options[:less_than_or_equal_to]
        result[:multipleOf]       = options[:other_than] if options[:other_than]
        result[:exclusiveMinimum] = options[:greater_than] if options[:greater_than]
        result[:exclusiveMaximum] = options[:less_than]    if options[:less_than]

        result
      end

      def convert_inclusion(validator)
        options = validator.options
        return {} unless options[:in]

        { enum: Array(options[:in]) }
      end

      def convert_format(validator)
        options = validator.options
        return {} unless options[:with]

        regexp = options[:with]

        if regexp.source == URI::MailTo::EMAIL_REGEXP.source
          { format: "email" }
        elsif regexp.source =~ /url|uri/i
          { format: "uri" }
        else
          { pattern: regexp.source }
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "spec/document"

module OpenapiBlocks
  class Builder # rubocop:disable Style/Documentation
    REQUIRED_CONFIG_ERROR = <<~MSG
      OpenapiBlocks is not configured. Add an initializer:

        # config/initializers/openapi_blocks.rb
        OpenapiBlocks.configure do |config|
          config.openapi_version = "3.1.0"  # required: "3.0.3" or "3.1.0"

          config.info do
            title   "My API"   # required
            version "1.0.0"    # required
          end
        end
    MSG

    def self.build
      new.build
    end

    def build
      validate_configuration!
      Spec::Document.new(openapi_classes).build
    end

    private

    def validate_configuration! # rubocop:disable Metrics/CyclomaticComplexity
      config = OpenapiBlocks.configuration
      errors = []

      unless config.configured?
        errors << "config.openapi_version or config.info must be defined — call OpenapiBlocks.configure"
      end
      errors << "config.info.title is required"   if config.info&.title.blank?
      errors << "config.info.version is required" if config.info&.version.blank?

      return if errors.empty?

      raise Error, "#{REQUIRED_CONFIG_ERROR}\nMissing:\n#{errors.map { |e| "  - #{e}" }.join("\n")}"
    end

    def openapi_classes
      ObjectSpace.each_object(Class).select do |klass|
        name = Module.instance_method(:name).bind_call(klass)
        next unless name&.end_with?("Openapi")

        klass < OpenapiBlocks::Base ||
          klass < OpenapiBlocks::Controller
      end
    end
  end
end

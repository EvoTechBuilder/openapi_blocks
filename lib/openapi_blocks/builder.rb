# frozen_string_literal: true

require_relative "spec/document"

module OpenapiBlocks
  class Builder # rubocop:disable Style/Documentation
    def self.build
      new.build
    end

    def build
      Spec::Document.new(openapi_classes).build
    end

    private

    def openapi_classes
      ObjectSpace.each_object(Class).select do |klass|
        name = Module.instance_method(:name).bind_call(klass)
        name&.end_with?("Openapi") &&
          (klass < OpenapiBlocks::Base || klass < OpenapiBlocks::Controller)
      end
    end
  end
end

# frozen_string_literal: true

require "active_support/all"
require "active_record"
require "oj"

require_relative "openapi_blocks/version"
require_relative "openapi_blocks/configuration"
require_relative "openapi_blocks/cache"
require_relative "openapi_blocks/file_watcher"
require_relative "openapi_blocks/middleware"
require_relative "openapi_blocks/schema/types"
require_relative "openapi_blocks/schema/extractor"
require_relative "openapi_blocks/schema/validator"
require_relative "openapi_blocks/routing/operation"
require_relative "openapi_blocks/routing/extractor"
require_relative "openapi_blocks/spec/components"
require_relative "openapi_blocks/spec/paths"
require_relative "openapi_blocks/spec/document"
require_relative "openapi_blocks/builder"
require_relative "openapi_blocks/engine"
require_relative "openapi_blocks/railtie"
require_relative "openapi_blocks/operation_builder"
require_relative "openapi_blocks/concerns/schemable"
require_relative "openapi_blocks/concerns/documentable"
require_relative "openapi_blocks/serialization"
require_relative "openapi_blocks/base"
require_relative "openapi_blocks/serializer"
require_relative "openapi_blocks/controller"

module OpenapiBlocks # rubocop:disable Style/Documentation
  class Error < StandardError; end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end

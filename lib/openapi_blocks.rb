# frozen_string_literal: true

require "active_support/all"
require "active_record"

require_relative "openapi_blocks/version"
require_relative "openapi_blocks/configuration"

# OpenapiBlock module
module OpenapiBlocks
  class Error < StandardError; end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end

# lib/openapi_blocks/configuration.rb
# frozen_string_literal: true

require_relative "configuration/info_builder"
require_relative "configuration/servers_builder"

module OpenapiBlocks
  class Configuration # rubocop:disable Style/Documentation
    attr_accessor :openapi_version, :watch

    def initialize
      @openapi_version = "3.1"
      @watch           = :development
      @info            = InfoBuilder.new
      @servers         = []
    end

    def info(&block)
      @info.instance_eval(&block) if block
      @info
    end

    def servers(&block)
      builder = ServersBuilder.new
      builder.instance_eval(&block) if block
      @servers = builder.servers
    end

    def to_h
      {
        info:    @info.to_h,
        servers: @servers.map(&:to_h)
      }
    end
  end
end

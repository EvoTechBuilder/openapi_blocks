# frozen_string_literal: true

module OpenapiBlocks
  module Generators
    class InstallGenerator < Rails::Generators::Base # rubocop:disable Style/Documentation
      source_root File.expand_path("templates", __dir__)

      desc "Creates an OpenapiBlocks initializer and mounts the engine in routes.rb"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/openapi_blocks.rb"
      end

      def mount_engine
        route 'mount OpenapiBlocks::Engine => "/docs"'
      end
    end
  end
end

# frozen_string_literal: true

module OpenapiBlocks
  module Generators
    class OpenapiGenerator < Rails::Generators::NamedBase # rubocop:disable Style/Documentation
      source_root File.expand_path("templates", __dir__)

      desc "Creates an OpenapiBlocks Controller class in app/openapi/"

      def create_openapi_file
        template "openapi.rb.tt", "app/openapi/#{file_name}_openapi.rb"
      end
    end
  end
end

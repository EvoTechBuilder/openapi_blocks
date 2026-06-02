# frozen_string_literal: true

module OpenapiBlocks
  module Generators
    class SerializerGenerator < Rails::Generators::NamedBase # rubocop:disable Style/Documentation
      source_root File.expand_path("templates", __dir__)

      desc "Creates an OpenapiBlocks Serializer class in app/serializers/"

      def create_serializer_file
        template "serializer.rb.tt", "app/serializers/#{file_name}_serializer.rb"
      end
    end
  end
end

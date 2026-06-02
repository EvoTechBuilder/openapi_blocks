# frozen_string_literal: true

require "rails"

module OpenapiBlocks
  class Railtie < Rails::Railtie # rubocop:disable Style/Documentation
    initializer "openapi_blocks.autoload", before: :set_autoload_paths do |app|
      app.config.eager_load_paths << app.root.join("app/openapi")
      app.config.eager_load_paths << app.root.join("app/serializers")
    end

    config.to_prepare do
      Dir[Rails.root.join("app/openapi/**/*.rb")].each { |f| require f }
      Dir[Rails.root.join("app/serializers/**/*.rb")].each { |f| require f }

      if OpenapiBlocks.configuration.auto_serialize
        [ActionController::Base, ActionController::API].each do |klass|
          klass.include(OpenapiBlocks::AutoSerialize) unless klass.ancestors.include?(OpenapiBlocks::AutoSerialize)
        end

        OpenapiBlocks::Registry.build!
      end
    end
  end
end

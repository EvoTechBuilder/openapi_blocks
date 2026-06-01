# frozen_string_literal: true

require "rails"

module OpenapiBlocks
  class Railtie < Rails::Railtie # rubocop:disable Style/Documentation
    initializer "openapi_blocks.middleware" do |app|
      app.middleware.use OpenapiBlocks::Middleware
    end

    initializer "openapi_blocks.autoload", before: :set_autoload_paths do |app|
      app.config.eager_load_paths << app.root.join("app/openapi")
    end

    config.to_prepare do
      Dir[Rails.root.join("app/openapi/**/*.rb")].each { |f| require f }
    end
  end
end

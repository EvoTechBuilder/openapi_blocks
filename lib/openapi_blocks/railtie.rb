# frozen_string_literal: true

require "rails"

module OpenapiBlocks
  class Railtie < Rails::Railtie # rubocop:disable Style/Documentation
    initializer "openapi_blocks.middleware" do |app|
      app.middleware.use OpenapiBlocks::Middleware
    end

    initializer "openapi_blocks.autoload" do |app|
      app.config.eager_load_paths << Rails.root.join("app/openapi")
    end
  end
end

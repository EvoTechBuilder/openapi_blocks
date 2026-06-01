# frozen_string_literal: true

require "rails"

module OpenapiBlocks
  class Engine < Rails::Engine # rubocop:disable Style/Documentation
    isolate_namespace OpenapiBlocks

    engine_name "openapi_blocks"

    # config.autoload_paths << File.expand_path("app/controllers", __dir__)
  end
end

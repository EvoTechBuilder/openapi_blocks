# frozen_string_literal: true

require "rails"

module OpenapiBlocks
  class Engine < Rails::Engine # rubocop:disable Style/Documentation
    isolate_namespace OpenapiBlocks

    routes.draw do
      get "openapi.json", to: "specs#show", defaults: { format: "json" }
      get "openapi.yaml", to: "specs#show", defaults: { format: "yaml" }
    end
  end
end

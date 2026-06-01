# frozen_string_literal: true

OpenapiBlocks::Engine.routes.draw do
  root to: "spec#ui"
  get "openapi.json", to: "spec#show", defaults: { format: "json" }
  get "openapi.yaml", to: "spec#show", defaults: { format: "yaml" }
end

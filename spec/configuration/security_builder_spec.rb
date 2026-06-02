# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Configuration::SecurityBuilder do # rubocop:disable Metrics/BlockLength
  subject(:builder) { described_class.new }

  describe "#bearer_token" do
    it "registers bearer auth scheme with default JWT format" do
      builder.bearer_token
      expect(builder.schemes[:bearerAuth]).to eq(
        { type: "http", scheme: "bearer", bearerFormat: "JWT" }
      )
    end

    it "accepts custom bearer format" do
      builder.bearer_token format: "OAuth2"
      expect(builder.schemes[:bearerAuth]).to include(bearerFormat: "OAuth2")
    end
  end

  describe "#api_key" do
    it "registers api key scheme with default name and location" do
      builder.api_key
      expect(builder.schemes[:apiKey]).to eq(
        { type: "apiKey", name: "X-API-Key", in: "header" }
      )
    end

    it "accepts custom name" do
      builder.api_key name: "X-Custom-Key"
      expect(builder.schemes[:apiKey]).to include(name: "X-Custom-Key")
    end

    it "accepts custom location" do
      builder.api_key in: :query
      expect(builder.schemes[:apiKey]).to include(in: "query")
    end
  end

  describe "#to_h" do
    it "returns all registered schemes" do
      builder.bearer_token
      builder.api_key

      expect(builder.to_h).to have_key(:bearerAuth)
      expect(builder.to_h).to have_key(:apiKey)
    end
  end
end

# frozen_string_literal: true

RSpec.describe OpenapiBlocks::Configuration do # rubocop:disable Metrics/BlockLength
  subject(:config) { described_class.new }

  it "has sensible defaults" do
    expect(config.openapi_version).to eq("3.1.0")
    expect(config.watch).to eq(:development)
  end

  it "returns a hash from to_h containing info and servers" do
    config.info do
      title "API"
    end

    config.servers do
      server do
        url "http://localhost"
      end
    end

    result = config.to_h
    expect(result).to have_key(:info)
    expect(result).to have_key(:servers)
    expect(result[:servers].first).to be_a(Hash)
  end

  describe "#openapi_version=" do
    it "accepts 3.0.3" do
      config.openapi_version = "3.0.3"
      expect(config.openapi_version).to eq("3.0.3")
    end

    it "accepts 3.1.0" do
      config.openapi_version = "3.1.0"
      expect(config.openapi_version).to eq("3.1.0")
    end

    it "raises ArgumentError for unsupported versions" do
      expect { config.openapi_version = "4.0" }.to raise_error(
        ArgumentError,
        /Unsupported OpenAPI version: "4.0"/
      )
    end

    it "raises ArgumentError for invalid values" do
      expect { config.openapi_version = "4.000012" }.to raise_error(ArgumentError)
    end
  end
end

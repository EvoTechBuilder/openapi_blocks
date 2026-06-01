# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Schema::Types do # rubocop:disable Metrics/BlockLength
  describe ".map" do # rubocop:disable Metrics/BlockLength
    it "maps integer" do
      expect(described_class.map("integer")).to eq({ type: "integer", format: "int32" })
    end

    it "maps bigint" do
      expect(described_class.map("bigint")).to eq({ type: "integer", format: "int64" })
    end

    it "maps float" do
      expect(described_class.map("float")).to eq({ type: "number", format: "float" })
    end

    it "maps decimal" do
      expect(described_class.map("decimal")).to eq({ type: "number", format: "double" })
    end

    it "maps string" do
      expect(described_class.map("string")).to eq({ type: "string" })
    end

    it "maps text" do
      expect(described_class.map("text")).to eq({ type: "string" })
    end

    it "maps boolean" do
      expect(described_class.map("boolean")).to eq({ type: "boolean" })
    end

    it "maps date" do
      expect(described_class.map("date")).to eq({ type: "string", format: "date" })
    end

    it "maps datetime" do
      expect(described_class.map("datetime")).to eq({ type: "string", format: "date-time" })
    end

    it "maps uuid" do
      expect(described_class.map("uuid")).to eq({ type: "string", format: "uuid" })
    end

    it "maps json" do
      expect(described_class.map("json")).to eq({ type: "object" })
    end

    it "maps jsonb" do
      expect(described_class.map("jsonb")).to eq({ type: "object" })
    end

    it "returns default string for unknown types" do
      expect(described_class.map("unknown_type")).to eq({ type: "string" })
    end
  end
end

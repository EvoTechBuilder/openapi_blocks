# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::OperationBuilder do # rubocop:disable Metrics/BlockLength
  subject(:builder) { described_class.new }

  describe "#summary" do
    it "sets and gets summary" do
      builder.summary "List users"
      expect(builder._summary).to eq("List users")
    end
  end

  describe "#description" do
    it "sets and gets description" do
      builder.description "Returns paginated users"
      expect(builder._description).to eq("Returns paginated users")
    end
  end

  describe "#tags" do
    it "sets and gets tags" do
      builder.tags "Users", "Admin"
      expect(builder._tags).to eq(%w[Users Admin])
    end
  end

  describe "#parameter" do
    it "registers a query parameter" do
      builder.parameter :page, in: :query, type: :integer, description: "Page number"
      expect(builder._parameters).to include(
        { name: :page, in: :query, type: :integer, description: "Page number", required: false }
      )
    end

    it "registers a required parameter" do
      builder.parameter :id, in: :path, type: :string, required: true
      expect(builder._parameters).to include(
        { name: :id, in: :path, type: :string, required: true }
      )
    end
  end

  describe "#response" do
    it "registers a response without schema" do
      builder.response 404, description: "Not found"
      expect(builder._responses["404"]).to eq({ description: "Not found" })
    end

    it "registers a response with schema" do
      builder.response 200, description: "Success", schema: :User
      expect(builder._responses["200"]).to eq({ description: "Success", schema: :User })
    end
  end

  describe "#security" do
    it "sets security schemes" do
      builder.security :bearerAuth
      expect(builder._security).to eq([{ bearerAuth: [] }])
    end

    it "sets multiple security schemes" do
      builder.security :bearerAuth, :apiKey
      expect(builder._security).to eq([{ bearerAuth: [] }, { apiKey: [] }])
    end
  end

  describe "#no_security!" do
    it "sets security to empty array" do
      builder.no_security!
      expect(builder._security).to eq([])
    end
  end
end

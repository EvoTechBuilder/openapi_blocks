# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Routing::Extractor do # rubocop:disable Metrics/BlockLength
  let(:app) do
    routes = ActionDispatch::Routing::RouteSet.new
    routes.draw do
      resources :articles
    end
    routes
  end

  subject(:extractor) { described_class.new(app) }

  describe "#extract" do # rubocop:disable Metrics/BlockLength
    it "generates paths for index" do
      expect(extractor.extract).to have_key("/articles")
      expect(extractor.extract["/articles"]).to have_key("get")
    end

    it "generates paths for create" do
      expect(extractor.extract["/articles"]).to have_key("post")
    end

    it "generates paths for show" do
      expect(extractor.extract).to have_key("/articles/{id}")
      expect(extractor.extract["/articles/{id}"]).to have_key("get")
    end

    it "generates paths for update with put and patch" do
      expect(extractor.extract["/articles/{id}"]).to have_key("put")
      expect(extractor.extract["/articles/{id}"]).to have_key("patch")
    end

    it "generates paths for destroy" do
      expect(extractor.extract["/articles/{id}"]).to have_key("delete")
    end

    it "includes tags based on controller name" do
      operation = extractor.extract["/articles"]["get"]
      expect(operation[:tags]).to eq(["Article"])
    end

    it "includes operationId" do
      operation = extractor.extract["/articles"]["get"]
      expect(operation[:operationId]).to eq("indexArticle")
    end

    it "includes path parameters for show" do
      operation = extractor.extract["/articles/{id}"]["get"]
      expect(operation[:parameters]).to include(
        { name: "id", in: "path", required: true, schema: { type: "string" } }
      )
    end

    it "includes requestBody for create" do
      operation = extractor.extract["/articles"]["post"]
      expect(operation[:requestBody]).to be_present
    end

    it "includes requestBody for update" do
      operation = extractor.extract["/articles/{id}"]["put"]
      expect(operation[:requestBody]).to be_present
    end

    it "does not include requestBody for destroy" do
      operation = extractor.extract["/articles/{id}"]["delete"]
      expect(operation[:requestBody]).to be_nil
    end

    it "includes 404 response for show" do
      operation = extractor.extract["/articles/{id}"]["get"]
      expect(operation[:responses]).to have_key("404")
    end

    it "includes 422 response for create" do
      operation = extractor.extract["/articles"]["post"]
      expect(operation[:responses]).to have_key("422")
    end

    context "with custom operation defined in OpenapiBlocks::Base subclass" do # rubocop:disable Metrics/BlockLength
      before do
        stub_const("Article", Class.new)
        stub_const("ArticleOpenapi", Class.new(OpenapiBlocks::Base) do
          operation :index do
            summary     "List all articles"
            description "Returns paginated articles"

            parameter :page, in: :query, type: :integer, description: "Page number"

            response 200, description: "List of articles", schema: { type: :array, items: :Article }
            response 401, description: "Unauthorized"
          end
        end)
      end

      it "uses custom summary" do
        operation = extractor.extract["/articles"]["get"]
        expect(operation[:summary]).to eq("List all articles")
      end

      it "uses custom description" do
        operation = extractor.extract["/articles"]["get"]
        expect(operation[:description]).to eq("Returns paginated articles")
      end

      it "includes custom query parameters" do
        operation = extractor.extract["/articles"]["get"]
        expect(operation[:parameters]).to include(
          { name: :page, in: "query", required: false, schema: { type: "integer" }, description: "Page number" }
        )
      end

      it "uses custom responses" do
        operation = extractor.extract["/articles"]["get"]
        expect(operation[:responses]).to have_key("200")
        expect(operation[:responses]).to have_key("401")
      end
    end
  end
end

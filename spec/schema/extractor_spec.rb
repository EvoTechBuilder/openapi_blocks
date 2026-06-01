# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Schema::Extractor do # rubocop:disable Metrics/BlockLength
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :extractor_users, force: true do |t|
        t.string  :name,      null: false
        t.string  :email,     null: false
        t.integer :age
        t.boolean :active, default: true
        t.string  :password_digest
        t.timestamps
      end
    end
  end

  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "extractor_users"

      def self.name
        "ExtractorUser"
      end

      validates :name,  presence: true
      validates :email, presence: true
    end
  end

  let(:openapi_class) do
    klass = Class.new(OpenapiBlocks::Base)
    klass.instance_variable_set(:@_model, model)
    klass
  end

  subject(:extractor) { described_class.new(openapi_class) }

  describe "#extract" do # rubocop:disable Metrics/BlockLength
    it "returns an object type" do
      expect(extractor.extract[:type]).to eq("object")
    end

    it "includes columns from the database" do
      expect(extractor.extract[:properties]).to have_key("name")
      expect(extractor.extract[:properties]).to have_key("email")
      expect(extractor.extract[:properties]).to have_key("age")
    end

    it "excludes password_digest by default" do
      expect(extractor.extract[:properties]).not_to have_key("password_digest")
    end

    it "maps column types correctly" do
      expect(extractor.extract[:properties]["age"]).to include(type: "integer")
      expect(extractor.extract[:properties]["active"]).to include(type: "boolean")
    end

    it "includes required fields from presence validations" do
      expect(extractor.extract[:required]).to include("name", "email")
    end

    context "with ignored fields" do
      before { openapi_class.ignore :age }

      it "excludes ignored fields" do
        expect(extractor.extract[:properties]).not_to have_key("age")
      end
    end

    context "with virtual attributes" do
      before { openapi_class.attribute :full_name, type: :string, read_only: true }

      it "includes virtual attributes" do
        expect(extractor.extract[:properties]).to have_key("full_name")
      end
    end

    context "with associations" do
      before { openapi_class.association :company }

      it "includes association as $ref" do
        expect(extractor.extract[:properties]["company"]).to eq(
          { "$ref" => "#/components/schemas/Company" }
        )
      end
    end

    context "with array associations" do
      before { openapi_class.association :posts, type: :array }

      it "includes array association with items $ref" do
        expect(extractor.extract[:properties]["posts"]).to eq(
          { type: "array", items: { "$ref" => "#/components/schemas/Post" } }
        )
      end
    end
  end
end

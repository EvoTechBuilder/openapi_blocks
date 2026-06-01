# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Spec::Components do # rubocop:disable Metrics/BlockLength
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :component_users, force: true do |t|
        t.string  :name,  null: false
        t.string  :email, null: false
        t.integer :age
        t.timestamps
      end
    end
  end

  let(:model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "component_users"

      def self.name
        "ComponentUser"
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

  subject(:components) { described_class.new([openapi_class]) }

  describe "#build" do # rubocop:disable Metrics/BlockLength
    it "generates User schema" do
      expect(components.build[:schemas]).to have_key("ComponentUser")
    end

    it "generates UserInput schema" do
      expect(components.build[:schemas]).to have_key("ComponentUserInput")
    end

    it "includes all columns in User schema" do
      properties = components.build[:schemas]["ComponentUser"][:properties]
      expect(properties).to have_key("name")
      expect(properties).to have_key("email")
      expect(properties).to have_key("age")
    end

    it "excludes id, created_at and updated_at from UserInput" do
      properties = components.build[:schemas]["ComponentUserInput"][:properties]
      expect(properties).not_to have_key("id")
      expect(properties).not_to have_key("created_at")
      expect(properties).not_to have_key("updated_at")
    end

    it "includes required fields in UserInput" do
      required = components.build[:schemas]["ComponentUserInput"][:required]
      expect(required).to include("name", "email")
    end

    context "with read_only virtual attributes" do
      before { openapi_class.attribute :full_name, type: :string, read_only: true }

      it "includes full_name in User schema" do
        properties = components.build[:schemas]["ComponentUser"][:properties]
        expect(properties).to have_key("full_name")
      end

      it "excludes full_name from UserInput schema" do
        properties = components.build[:schemas]["ComponentUserInput"][:properties]
        expect(properties).not_to have_key("full_name")
      end
    end

    context "with writable virtual attributes" do
      before { openapi_class.attribute :nickname, type: :string }

      it "includes nickname in User schema" do
        properties = components.build[:schemas]["ComponentUser"][:properties]
        expect(properties).to have_key("nickname")
      end

      it "includes nickname in UserInput schema" do
        properties = components.build[:schemas]["ComponentUserInput"][:properties]
        expect(properties).to have_key("nickname")
      end
    end
  end
end

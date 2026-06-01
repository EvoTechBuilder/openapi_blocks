# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiBlocks::Schema::Validator do # rubocop:disable Metrics/BlockLength
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      def self.name
        "ValidatorTestModel"
      end

      validates :name,  length: { minimum: 2, maximum: 100 }
      validates :age,   numericality: { greater_than: 0, less_than_or_equal_to: 120 }
      validates :role,  inclusion: { in: %w[admin user guest] }
      validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
      validates :code,  length: { is: 6 }
    end
  end

  subject(:validator) { described_class.new(model) }

  describe "#extract" do
    it "maps length minimum to minLength" do
      expect(validator.extract["name"]).to include(minLength: 2)
    end

    it "maps length maximum to maxLength" do
      expect(validator.extract["name"]).to include(maxLength: 100)
    end

    it "maps length is to minLength and maxLength" do
      expect(validator.extract["code"]).to include(minLength: 6, maxLength: 6)
    end

    it "maps numericality greater_than to minimum" do
      expect(validator.extract["age"]).to include(minimum: 1)
    end

    it "maps numericality less_than_or_equal_to to maximum" do
      expect(validator.extract["age"]).to include(maximum: 120)
    end

    it "maps inclusion to enum" do
      expect(validator.extract["role"]).to include(enum: %w[admin user guest])
    end

    it "maps URI::MailTo::EMAIL_REGEXP to format email" do
      expect(validator.extract["email"]).to include(format: "email")
    end
  end
end

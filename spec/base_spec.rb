# frozen_string_literal: true

RSpec.describe OpenapiBlocks::Base do # rubocop:disable Metrics/BlockLength
  before do
    # define a dummy model class for inference matching the test class name (TestUser)
    stub_const("TestUser", Class.new)

    # clean any test helper classes that may persist
    Object.send(:remove_const, :TestUserOpenapi) if Object.const_defined?(:TestUserOpenapi)
  end

  it "infers the model from the class name" do
    class TestUserOpenapi < OpenapiBlocks::Base; end # rubocop:disable Lint/ConstantDefinitionInBlock
    expect(TestUserOpenapi.model).to eq(TestUser)
  end

  it "raises an error when the model cannot be inferred" do
    expect do
      class NoModelOpenapi < OpenapiBlocks::Base; end # rubocop:disable Lint/ConstantDefinitionInBlock
      NoModelOpenapi.model
    end.to raise_error(OpenapiBlocks::Error)
  end

  it "registers ignored attributes, associations and virtual attributes" do
    class DummyOpenapi < OpenapiBlocks::Base; end # rubocop:disable Lint/ConstantDefinitionInBlock

    DummyOpenapi.ignore :a, :b
    expect(DummyOpenapi._ignored).to include("a", "b")

    DummyOpenapi.association :company, type: :object
    expect(DummyOpenapi._associations).to include({ name: :company, type: :object, input: true })

    DummyOpenapi.association :profile, input: false
    expect(DummyOpenapi._associations).to include({ name: :profile, type: nil, input: false })

    DummyOpenapi.attribute :token, type: :string, read_only: true
    expect(DummyOpenapi._virtual_attributes.map { |v| v[:name] }).to include(:token)
  end

  it "registers operations via OperationBuilder" do
    class OpsOpenapi < OpenapiBlocks::Base; end # rubocop:disable Lint/ConstantDefinitionInBlock

    OpsOpenapi.operation :index do
      summary "List"
    end

    expect(OpsOpenapi._operations).to have_key(:index)
    builder = OpsOpenapi._operations[:index]
    expect(builder._summary).to eq("List")
  end
end

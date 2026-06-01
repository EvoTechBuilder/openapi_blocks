# frozen_string_literal: true

RSpec.describe OpenapiBlocks::Cache do
  subject(:cache) { described_class.new }

  it "stores and retrieves values" do
    cache.set(:foo, "bar")
    expect(cache.get(:foo)).to eq("bar")
    expect(cache.cached?(:foo)).to be true
  end

  it "invalidates a specific key" do
    cache.set(:a, 1)
    cache.set(:b, 2)
    cache.invalidate!(:a)
    expect(cache.cached?(:a)).to be false
    expect(cache.get(:b)).to eq(2)
  end

  it "clears all keys when no key provided" do
    cache.set(:x, 9)
    cache.invalidate!
    expect(cache.cached?(:x)).to be false
  end
end

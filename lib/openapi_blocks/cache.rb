# frozen_string_literal: true

module OpenapiBlocks
  class Cache # rubocop:disable Style/Documentation
    def initialize
      @store = {}
      @mutex = Mutex.new
    end

    def get(key)
      @store[key]
    end

    def set(key, value)
      @mutex.synchronize { @store[key] = value }
    end

    def invalidate!(key = nil)
      @mutex.synchronize do
        key ? @store.delete(key) : @store.clear
      end
    end

    def cached?(key)
      @store.key?(key)
    end
  end
end

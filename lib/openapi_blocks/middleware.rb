# frozen_string_literal: true

require_relative "file_watcher"
require_relative "cache"

module OpenapiBlocks
  class Middleware # rubocop:disable Style/Documentation
    CACHE_KEY = :openapi_spec

    def initialize(app)
      @app          = app
      @cache        = Cache.new
      @file_watcher = FileWatcher.new(root_path)
    end

    def call(env)
      @app.call(env)
    ensure
      invalidate_if_stale!
    end

    private

    def invalidate_if_stale!
      return unless watch_enabled?
      return unless @file_watcher.stale?

      @cache.invalidate!(CACHE_KEY)
      @file_watcher.snapshot!
    end

    def spec
      @cache.set(CACHE_KEY, Builder.build) unless @cache.cached?(CACHE_KEY)

      @cache.get(CACHE_KEY)
    end

    def watch_enabled?
      watched_envs.include?(current_env)
    end

    def watched_envs
      Array(OpenapiBlocks.configuration.watch)
    end

    def current_env
      Rails.env.to_sym
    end

    def root_path
      Rails.root.to_s
    end
  end
end

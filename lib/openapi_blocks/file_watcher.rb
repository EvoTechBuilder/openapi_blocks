# frozen_string_literal: true

module OpenapiBlocks
  class FileWatcher # rubocop:disable Style/Documentation
    WATCH_PATTERNS = [
      "app/openapi/**/*.rb",
      "app/models/**/*.rb",
      "config/routes.rb",
      "db/schema.rb"
    ].freeze

    def initialize(root_path)
      @root_path = root_path
      @mtimes    = {}
      snapshot!
    end

    def stale?
      watched_files.any? do |file|
        mtime(file) != @mtimes[file]
      end
    end

    def snapshot!
      watched_files.each do |file|
        @mtimes[file] = mtime(file)
      end
    end

    private

    def watched_files
      WATCH_PATTERNS.flat_map do |pattern|
        Dir.glob(File.join(@root_path, pattern))
      end
    end

    def mtime(file)
      File.exist?(file) ? File.mtime(file) : nil
    end
  end
end

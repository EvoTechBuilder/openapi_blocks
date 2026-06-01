# frozen_string_literal: true

require "rails"
require "active_record"
require "openapi_blocks"

# Setup SQLite in memory for tests
ActiveRecord::Base.establish_connection(
  adapter:  "sqlite3",
  database: ":memory:"
)

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

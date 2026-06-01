# frozen_string_literal: true

require_relative "lib/openapi_blocks/version"

Gem::Specification.new do |spec|
  spec.name = "openapi_blocks"
  spec.version = OpenapiBlocks::VERSION
  spec.authors = ["Caio Santos"]
  spec.email = ["caio.francelinosena@gmail.com"]

  spec.summary = "DSL to generate OpenAPI 3.0/3.1 documentation for Rails applications"
  spec.description = "Generates OpenAPI specs automatically from ActiveRecord models, ActiveModel validations and Rails routes, inspired by ActiveModel::Serializer."
  spec.homepage = "https://github.com/evotechbuilder/openapi_blocks"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"

  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "sqlite3",     "~> 1.4"
end

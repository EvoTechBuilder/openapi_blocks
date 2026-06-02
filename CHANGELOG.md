# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-06-01

### Changed
- `association` DSL now uses `read_only: true` instead of `input: false` for consistency with `attribute` DSL

## [0.2.0] - 2026-06-01

### Added

- `OpenapiBlocks::OperationBuilder` DSL for customizing operations per action
- `summary` and `description` customization per operation
- `parameter` DSL for query parameters with `in:`, `type:`, `description:` and `required:` options
- `response` DSL with `description:` and `schema:` options
- `tags` DSL on `OpenapiBlocks::Base` for custom tags per OpenAPI class
- `tags` DSL on `OperationBuilder` for custom tags per operation
- Tag resolution priority: operation tags > class tags > inferred from controller name
- `OpenapiBlocks::Configuration::SecurityBuilder` with `bearer_token` and `api_key` DSL
- Global `security` configuration in initializer
- Per-operation `security` and `no_security!` DSL in `OperationBuilder`
- `securitySchemes` generated automatically in `components`
- `tags` array generated at document root level from paths
- Swagger UI served at root of mounted engine (`/docs`)
- `SpecController#ui` action serving Swagger UI with JSON/YAML spec switcher
- `association` DSL now supports `input: false` to exclude from input schema
- Associations excluded from `required` fields automatically
- `resolve_schema` classifies symbol references (`:user` → `User`)
- Automatic `UserInput` schema excludes `read_only: true` virtual attributes
- Validation for `openapi_version` — raises `ArgumentError` for unsupported versions
- RSpec coverage for `OperationBuilder`, `SecurityBuilder`, tags and security

### Fixed

- `find_openapi_class` uses `Object.const_get` instead of `ObjectSpace` for reliability
- `openapi` version field correctly outputs `3.1.0` instead of `3.1`

## [0.1.0] - 2026-06-01

### Added

- Initial project structure with gemspec, RSpec and RuboCop setup (`71be639`)
- `OpenapiBlocks::Configuration` with DSL for `info`, `servers` and `openapi_version` (3.0 / 3.1)
- `OpenapiBlocks::Cache` thread-safe in-memory cache with `Mutex`
- `OpenapiBlocks::FileWatcher` monitoring `app/openapi`, `app/models`, `config/routes.rb` and `db/schema.rb`
- `OpenapiBlocks::Middleware` with automatic cache invalidation on file changes
- `OpenapiBlocks::Railtie` for automatic middleware injection and eager loading of `app/openapi` (`28d9cab`)
- `OpenapiBlocks::Schema::Extractor` for automatic schema generation from ActiveRecord columns
- `OpenapiBlocks::Schema::Validator` for mapping ActiveModel validations to OpenAPI restrictions (`minLength`, `maxLength`, `minimum`, `maximum`, `enum`, `pattern`, `format`)
- `OpenapiBlocks::Schema::Types` mapping ActiveRecord types to OpenAPI types (`1256d31`)
- `OpenapiBlocks::Routing::Operation` and `OpenapiBlocks::Routing::Extractor` for automatic path generation from Rails routes
- `OpenapiBlocks::Spec::Document`, `OpenapiBlocks::Spec::Paths` and `OpenapiBlocks::Spec::Components` for OpenAPI document assembly
- `OpenapiBlocks::Builder` for orchestrating spec generation (`db5910a`)
- `OpenapiBlocks::Engine` mountable in `config/routes.rb` exposing `/openapi.json` and `/openapi.yaml`
- `OpenapiBlocks::SpecController` replacing previous implementation (`cbacd18`)
- Automatic `UserInput` schema generation for `POST`, `PUT` and `PATCH` request bodies
- Validation merging into schema properties
- Automatic filtering of internal Rails routes (`rails/`, `action_mailbox/`, `active_storage/`) (`35737ab`)
- `OpenapiBlocks::OperationBuilder` DSL for customizing operations per action (`operation :index`, `:show`, `:create`, `:update`, `:destroy`)
- `summary` and `description` customization per operation
- `parameter` DSL for query parameters with `in:`, `type:`, `description:` and `required:` options
- `response` DSL for custom responses with `description:` and `schema:` options
- Schema resolution supporting `Symbol` (`schema: :User`) and array (`schema: { type: :array, items: :User }`) references
- Fallback to auto-generated responses when no custom `operation` block is defined (`0055aa3`)
- RSpec coverage for `Schema::Types`, `Schema::Validator`, `Schema::Extractor`, `Routing::Extractor`, `Spec::Components` and `Configuration`
- Validation for `openapi_version` — raises `ArgumentError` for unsupported versions
- `read_only: true` virtual attributes excluded from `UserInput` schema
- `OpenapiBlocks::Configuration::SecurityBuilder` with `bearer_token` and `api_key` DSL
- Global `security` configuration in initializer
- Per-operation `security` and `no_security!` DSL in `OperationBuilder`
- `securitySchemes` generated automatically in `components`
- `tags` array generated at document root level from paths
- `association` DSL now supports `input: false` to exclude from `UserInput`
- Associations excluded from `required` fields automatically
- `resolve_schema` now classifies symbol references (`:user` → `User`)
- `tags` DSL on `OpenapiBlocks::Base` for custom tags per OpenAPI class
- `tags` DSL on `OperationBuilder` for custom tags per operation
- Tag resolution priority: operation tags > class tags > inferred from controller name
- Swagger UI served at root of mounted engine (`/docs`)
- `SpecController#ui` action serving Swagger UI with JSON/YAML spec switcher

[Unreleased]: https://github.com/evotechbuilder/openapi_blocks/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/evotechbuilder/openapi_blocks/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/evotechbuilder/openapi_blocks/releases/tag/v0.1.0

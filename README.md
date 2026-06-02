# OpenapiBlocks

OpenapiBlocks is a Rails gem that automatically generates OpenAPI 3.0/3.1 documentation from your ActiveRecord models, ActiveModel validations, and Rails routes — inspired by [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

Versão em português brasileiro: README.pt-BR.md

No manual annotation. No DSL noise in your controllers. Just declare what to expose and the spec is generated automatically. Includes a high-performance built-in serializer — ~3.6× faster than `as_json` with consistent linear scaling from 10 to 5000 records.

## Key changes (recent)
- `OpenapiBlocks::Resource` and `OpenapiBlocks::Controller` introduced as a cleaner alternative to `OpenapiBlocks::Base` — separating serialization from documentation concerns.
- Default OpenAPI version is `3.1.0` (supported: `3.1.0`, `3.0.3`).
- Scalar UI is now served at `/docs/scalar` alongside Swagger UI at `/docs`.
- Swagger UI uses same-origin spec endpoints to avoid CORS issues.
- YAML output is normalized to use string keys so Swagger UI accepts the `openapi` version field.
- `association` DSL uses `read_only: true` to mark fields as response-only and exclude them from `*Input` schemas.
- `tags` are generated at the document root from paths and can be customized via the `tags` DSL on classes and operations.
- Schema references accept `Symbol` (e.g. `schema: :user`) and array items can be symbol references (e.g. `items: :user`).
- Serializer uses `class_eval` to compile a monolithic extractor method per class at boot — eliminating per-object branching, lambda indirection, and runtime `respond_to?` checks.

---

## Installation

Add to your Gemfile:

```ruby
gem "openapi_blocks"
```

Then run:

```bash
bundle install
```

---

## Setup

### 1. Mount the Engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount OpenapiBlocks::Engine => "/docs"

  resources :users
end
```

This exposes:

```
GET /docs               ->  Scalar UI
GET /docs/swagger       ->  Swagger UI
GET /docs/openapi.json  ->  OpenAPI spec in JSON
GET /docs/openapi.yaml  ->  OpenAPI spec in YAML
```

### 2. Configure the initializer

```ruby
# config/initializers/openapi_blocks.rb
OpenapiBlocks.configure do |config|
  config.openapi_version = "3.1.0"  # "3.0.3" or "3.1.0"

  config.info do
    title       "My API"
    version     "1.0.0"
    description "API documentation generated automatically"

    contact do
      name  "My Team"
      email "api@mycompany.com"
      url   "https://mycompany.com"
    end

    license do
      name "MIT"
      url  "https://opensource.org/licenses/MIT"
    end
  end

  config.servers do
    server do
      url         "https://api.mycompany.com"
      description "Production"
    end

    server do
      url         "http://localhost:3000"
      description "Development"
    end
  end

  config.watch = :development  # auto-reload on file changes

  # optional: security schemes
  config.security do
    bearer_token format: "JWT"
    api_key      name: "X-API-Key", in: :header
  end
end
```

---

## Usage

OpenapiBlocks provides two base classes with distinct responsibilities:

- `OpenapiBlocks::Resource` — defines the model, fields, associations, and serialization logic.
- `OpenapiBlocks::Controller` — defines the API operations, parameters, and responses for documentation.
- `OpenapiBlocks::Base` — legacy base class that combines both concerns. Still supported.

### Resource + Controller (recommended)

```
app/
  openapi/
    user_resource.rb    ->  serialization + schema
    user_openapi.rb     ->  API documentation
    post_resource.rb
    post_openapi.rb
```

```ruby
# app/openapi/user_resource.rb
class UserResource < OpenapiBlocks::Resource
  # model User is inferred automatically from the class name

  ignore :password_digest, :reset_password_token

  association :posts, type: :array, read_only: true

  attribute :full_name,    type: :string, read_only: true
  attribute :access_token, type: :string, read_only: true
  attribute :nickname,     type: :string

  # method defined here — called on the resource instance
  def full_name
    "#{object.name} (#{object.email})"
  end

  # or omit the method and it delegates to the model automatically
end
```

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  resource UserResource
  controller UsersController

  tags "Users"

  operation :index do
    summary     "List all users"
    description "Returns a paginated list of active users"

    parameter :page,     in: :query, type: :integer, description: "Page number"
    parameter :per_page, in: :query, type: :integer, description: "Items per page"

    response 200, description: "List of users", schema: { type: :array, items: :User }
    response 401, description: "Unauthorized"
  end

  operation :show do
    summary "Get a user"

    response 200, description: "User found", schema: :User
    response 404, description: "User not found"

    no_security!
  end
end
```

```ruby
# app/controllers/users_controller.rb
def index
  render json: UserResource.serialize(User.includes(:posts))
end

def show
  render json: UserResource.serialize(User.find(params[:id]))
end
```

### Base (legacy, single class)

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Base
  tags "Users"

  ignore :password_digest

  association :posts, type: :array, read_only: true

  attribute :full_name, type: :string, read_only: true

  operation :index do
    summary  "List all users"
    response 200, description: "List of users", schema: { type: :array, items: :User }
  end
end
```

```ruby
# app/controllers/users_controller.rb
def index
  render json: UserOpenapi.serialize(User.includes(:posts))
end
```

---

## Serializer

The built-in serializer compiles a monolithic extractor method per class at boot time using `class_eval`. There are no loops, no lambda indirection, and no runtime branching per object.

### Performance (200 records, arm64, Ruby 4.0)

| | i/s | μs/i | vs serialize |
|---|---|---|---|
| serialize | 4 239 | 235 | — |
| to_json | 1 444 | 692 | 2.94× slower |
| as_json | 1 186 | 843 | 3.58× slower |
| oj+as_json | 1 126 | 888 | 3.77× slower |

Scaling is linear — the 3.6× advantage over `as_json` holds from 10 to 5000 records.

### Virtual attributes and method resolution

| Declared with | Method in resource? | Calls |
|---|---|---|
| `attribute :full_name` | yes | `resource_instance.full_name` |
| `attribute :full_name` | no | `object.full_name` (delegated to model) |
| column in db | — | `object.full_name` (direct) |

### Association serializer resolution

For each association, the serializer resolves the serializer class in this order:

1. `PostResource` — has `serialize`, used directly.
2. `PostOpenapi` — is a `Controller`, delegates to its `_resource`.
3. Fallback — calls `as_json` on the association value.

---

## What is generated automatically

Given this model:

```ruby
class User < ApplicationRecord
  validates :name,  presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age,   numericality: { greater_than: 0 }
  validates :role,  inclusion: { in: %w[admin user guest] }
end
```

OpenapiBlocks generates:

- `User` schema from `db/schema.rb` columns and types
- `UserInput` schema for POST, PUT and PATCH request bodies (without `id`, `created_at`, `updated_at` and `read_only` fields)
- `required` fields from `presence: true` validations
- `minLength`, `maxLength` from `length` validations
- `minimum`, `maximum` from `numericality` validations
- `enum` from `inclusion` validations
- `format: "email"` from format validations
- All paths from `config/routes.rb`

---

## Security

Configure global security schemes in the initializer:

```ruby
config.security do
  bearer_token format: "JWT"                    # Authorization: Bearer <token>
  api_key      name: "X-API-Key", in: :header   # X-API-Key: <key>
end
```

Override security per operation:

```ruby
operation :index do
  security :bearerAuth   # only bearer on this operation
end

operation :show do
  no_security!           # public endpoint — no auth required
end
```

---

## Associations

```ruby
association :company                                  # belongs_to — $ref to Company schema
association :posts, type: :array                      # has_many — array of $ref to Post schema
association :posts, type: :array, read_only: true     # excluded from UserInput (response only)
```

---

## Virtual Attributes

Virtual attributes are fields that exist in the API response but not in the database.

| Option | Description | Appears in User | Appears in UserInput |
|---|---|:---:|:---:|
| `read_only: true` | Calculated or system-generated fields | YES | NO |
| `read_only: false` | Fields the client can send and receive | YES | YES |

```ruby
attribute :full_name,    type: :string, read_only: true   # response only
attribute :access_token, type: :string, read_only: true   # response only
attribute :nickname,     type: :string                    # request and response
```

---

## Type Mapping

| ActiveRecord type | OpenAPI type |
|---|---|
| integer | integer / int32 |
| bigint | integer / int64 |
| float | number / float |
| decimal | number / double |
| string | string |
| text | string |
| boolean | boolean |
| date | string / date |
| datetime | string / date-time |
| uuid | string / uuid |
| json / jsonb | object |

---

## Auto-reload in Development

OpenapiBlocks watches for changes in:

```
app/openapi/**/*.rb
app/models/**/*.rb
config/routes.rb
db/schema.rb
```

The spec is automatically regenerated on the next request to `/docs/openapi.json` whenever any of these files change. No server restart needed.

---

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

---

## License

MIT (LICENSE.txt)
# OpenapiBlocks

OpenapiBlocks is a Rails gem that automatically generates OpenAPI 3.0/3.1 documentation from your ActiveRecord models, ActiveModel validations, and Rails routes — inspired by ActiveModel::Serializer (https://github.com/rails-api/active_model_serializers).

Versão em português brasileiro: README.pt-BR.md

No manual annotation. No DSL noise in your controllers. Just declare what to expose and the spec is generated automatically. Includes a high-performance built-in serializer — ~3.6× faster than as_json with consistent linear scaling from 10 to 5000 records.

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

## Generators

OpenapiBlocks provides three generators to get you started quickly.

### Install

```bash
rails generate openapi_blocks:install
```

Creates `config/initializers/openapi_blocks.rb` with all available options commented out, and mounts the engine in `config/routes.rb`:

```ruby
mount OpenapiBlocks::Engine => "/docs"
```

### Openapi

```bash
rails generate openapi_blocks:openapi User
```

Creates `app/openapi/user_openapi.rb` with all available DSL options commented out:

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  # resource UserSerializer
  # controller UsersController

  # tags "Users"

  # operation :index do
  #   summary     "List all users"
  #   response 200, description: "List of users", schema: { type: :array, items: :User }
  # end
end
```

### Serializer

```bash
rails generate openapi_blocks:serializer User
```

Creates `app/serializers/user_serializer.rb` with all available DSL options commented out:

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < OpenapiBlocks::Serializer
  # ignore :password_digest, :reset_password_token

  # association :posts, type: :array, read_only: true
  # association :company

  # attribute :full_name, type: :string, read_only: true
  # def full_name
  #   "#{object.first_name} #{object.last_name}"
  # end
end
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
GET /docs               ->  Scalar UI (default)
GET /docs/swagger       ->  Swagger UI
GET /docs/openapi.json  ->  OpenAPI spec in JSON
GET /docs/openapi.yaml  ->  OpenAPI spec in YAML
```

### 2. Configure the initializer

OpenapiBlocks.configure is required. The gem raises OpenapiBlocks::Error on the first request if it was never called or if info.title / info.version are blank.

```ruby
# config/initializers/openapi_blocks.rb
OpenapiBlocks.configure do |config|
  config.openapi_version = "3.1.0"  # required — "3.0.3" or "3.1.0"

  config.info do
    title       "My API"    # required
    version     "1.0.0"     # required
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

  config.watch          = :development  # auto-reload on file changes
  config.auto_serialize = true          # optional — see Auto Serialization below

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

- OpenapiBlocks::Serializer — defines the model, fields, associations, and serialization logic. Lives in app/serializers/.
- OpenapiBlocks::Controller — defines API operations, parameters, and responses for documentation. Lives in app/openapi/.
- OpenapiBlocks::Base — legacy base class that combines both concerns. Still supported.

### Recommended: Serializer + Controller

```
app/
  serializers/
    user_serializer.rb    ->  serialization + schema
    post_serializer.rb
  openapi/
    user_openapi.rb       ->  API documentation
    post_openapi.rb
```

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < OpenapiBlocks::Serializer
  # model User is inferred automatically from the class name

  ignore :password_digest, :reset_password_token

  association :posts, type: :array, read_only: true

  attribute :full_name,    type: :string, read_only: true
  attribute :access_token, type: :string, read_only: true
  attribute :nickname,     type: :string

  # method defined here — called on the serializer instance
  def full_name
    "#{object.name} (#{object.email})"
  end

  # or omit the method and it delegates to the model automatically
end
```

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  resource   UserSerializer  # links to the serializer — schema is derived from it
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

#### How the OpenAPI schema is generated

When `resource UserSerializer` is declared in a `Controller`, OpenapiBlocks derives the OpenAPI schema directly from the serializer — not from the model. This guarantees that what is documented is exactly what the API returns.

The schema is built from three sources on the serializer:

- ActiveRecord columns — read from `db/schema.rb` via the inferred model. Column types are mapped to OpenAPI types automatically.
- `attribute` declarations — virtual fields not present in the database. Fields declared with `read_only: true` appear in the `User` response schema but are excluded from the `UserInput` request schema.
- `association` declarations — resolved as `$ref` to the associated schema. Associations declared with `read_only: true` appear in the response but are excluded from `UserInput`.
- `ignore` declarations — columns excluded from both schemas.

The `UserInput` schema (used in POST, PUT and PATCH request bodies) is derived automatically from the `User` schema by removing `id`, `created_at`, `updated_at`, and any field marked `read_only: true`.

```ruby
# app/controllers/users_controller.rb
def index
  render json: UserSerializer.serialize(User.includes(:posts))
end

def show
  render json: UserSerializer.serialize(User.find(params[:id]))
end
```

### Legacy: Base (single class)

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

## Auto Serialization

When `config.auto_serialize = true`, OpenapiBlocks intercepts every `render json:` call and automatically applies the registered serializer — no explicit serializer call needed in controllers.

```ruby
# config/initializers/openapi_blocks.rb
config.auto_serialize = true
```

```ruby
# app/controllers/users_controller.rb
def index
  render json: User.all  # automatically serialized by UserSerializer
end

def show
  render json: @user  # automatically serialized by UserSerializer
end
```

Serializer registration is automatic by convention (UserSerializer -> User). For explicit registration:

```ruby
class AdminUserSerializer < OpenapiBlocks::Serializer
  serializes User  # explicitly maps this serializer to the User model
end
```

If no serializer is found, OpenapiBlocks falls back to default Rails rendering and logs a warning.

---

## Serializer

The built-in serializer compiles a monolithic extractor method per class at boot time using class_eval. There are no loops, no lambda indirection, and no runtime branching per object.

### Performance (200 records, arm64, Ruby 4.0)

| Method     | i/s   | μs/i | vs serialize |
|------------|-------|------|--------------|
| serialize  | 4 504 | 198  | —            |
| to_json    | 1 444 | 692  | 2.89x slower |
| as_json    | 1 179 | 453  | 2.81x slower |
| oj+as_json | 1 126 | 572  | 2.89x slower |
| AMS        |   559 | 178  | 9.02x slower |

Scaling is linear — the 2.81x advantage over as_json holds from 10 to 5000 records.

### Memory Allocation

OpenapiBlocks:  20MB / 225k objects  — fastest and lowest memory
as_json:       116MB / 1.2M objects  — 2.81x slower, 5.6x more memory
AMS:           260MB / 2.7M objects  — 9x slower,   13x more memory

### Virtual attributes and method resolution

| Declared with        | Method in serializer? | Calls                                 |
| -------------------- | --------------------- | ------------------------------------- |
| attribute :full_name | yes                   | serializer_instance.full_name         |
| attribute :full_name | no                    | object.full_name (delegated to model) |
| column in db         | —                     | object.attribute (direct)             |

### Association serializer resolution

For each association, the serializer resolves the serializer class in this order:

1. PostSerializer — has serialize, used directly.
2. PostOpenapi — is a Controller, delegates to its resource.
3. Fallback — calls as_json on the association value.

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

- User schema from db/schema.rb columns and types
- UserInput schema for POST, PUT and PATCH request bodies (without id, created_at, updated_at and read_only fields)
- required fields from presence: true validations
- minLength, maxLength from length validations
- minimum, maximum from numericality validations
- enum from inclusion validations
- format: "email" from format validations
- All paths from config/routes.rb

---

## Security

Configure global security schemes in the initializer:

```ruby
config.security do
  bearer_token format: "JWT"                   # Authorization: Bearer <token>
  api_key      name: "X-API-Key", in: :header  # X-API-Key: <key>
end
```

Override security per operation:

```ruby
operation :index do
  security :bearerAuth  # only bearer on this operation
end

operation :show do
  no_security!          # public endpoint — no auth required
end
```

---

## Associations

```ruby
association :company                               # belongs_to — $ref to Company schema
association :posts, type: :array                   # has_many — array of $ref to Post schema
association :posts, type: :array, read_only: true  # excluded from UserInput (response only)
```

---

## Virtual Attributes

Virtual attributes are fields that exist in the API response but not in the database.

| Option           | Description                            | Appears in User | Appears in UserInput |
| ---------------- | -------------------------------------- | :-------------: | :------------------: |
| read_only: true  | Calculated or system-generated fields  |       YES       |          NO          |
| read_only: false | Fields the client can send and receive |       YES       |         YES          |

```ruby
attribute :full_name,    type: :string, read_only: true  # response only
attribute :access_token, type: :string, read_only: true  # response only
attribute :nickname,     type: :string                   # request and response
```

---

## Type Mapping

| ActiveRecord type | OpenAPI type       |
| ----------------- | ------------------ |
| integer           | integer / int32    |
| bigint            | integer / int64    |
| float             | number / float     |
| decimal           | number / double    |
| string            | string             |
| text              | string             |
| boolean           | boolean            |
| date              | string / date      |
| datetime          | string / date-time |
| uuid              | string / uuid      |
| json / jsonb      | object             |

---

## Auto-reload in Development

OpenapiBlocks watches for changes in:

```
app/serializers/**/*.rb
app/openapi/**/*.rb
app/models/**/*.rb
config/routes.rb
db/schema.rb
```

The spec is automatically regenerated on the next request to /docs/openapi.json whenever any of these files change. No server restart needed.

---

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

---

## License

MIT (LICENSE.txt)

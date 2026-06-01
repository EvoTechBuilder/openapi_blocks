

OpenapiBlocks is a Rails gem that automatically generates OpenAPI 3.0/3.1 documentation from your ActiveRecord models, ActiveModel validations, and Rails routes — inspired by [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

Versão em português brasileiro: [README.pt-BR.md](README.pt-BR.md)

No manual annotation. No DSL noise in your controllers. Just declare what to expose and the spec is generated automatically.

---

## Installation

Add to your `Gemfile`:

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
config/routes.rb
````

Rails.application.routes.draw do
mount OpenapiBlocks::Engine => "/docs"resources :users
end

This exposes:
<br />
GET /docs/openapi.json
<br />
GET /docs/openapi.yaml

### 2. Configure the initializer

```ruby
# config/initializers/openapi_blocks.rb

OpenapiBlocks.configure do |config|
    config.openapi_version = "3.1"  # "3.0" or "3.1"
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
end
```

---

## Usage

### Creating an OpenAPI class

Create a file in `app/openapi/` following the same naming convention as ActiveModel::Serializer:app/
openapi/
user_openapi.rb     →  User model
post_openapi.rb     →  Post model
order_openapi.rb    →  Order model

```ruby
# app/openapi/user_openapi.rb

class UserOpenapi < OpenapiBlocks::Base
    # model User is inferred automatically from the class nameopt-out sensitive or unnecessary fields
    ignore :password_digest, :reset_password_token
    
    #opt-in associations
    association :company
    association :posts, type: :array
    
    #virtual attributes (not in the database)
    attribute :full_name,  type: :string
    attribute :token,      type: :string, read_only: true
end
```

### What is generated automatically

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
- `UserInput` schema for `POST`, `PUT` and `PATCH` request bodies (without `id`, `created_at`, `updated_at`)
- `required` fields from `presence: true` validations
- `minLength`, `maxLength` from `length` validations
- `minimum`, `maximum` from `numericality` validations
- `enum` from `inclusion` validations
- `format: "email"` from format validations
- All paths from `config/routes.rb`

### Customizing operations

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Base
    operation :index do
        summary     "List all users"
        description "Returns a paginated list of active users"
        parameter :page,     in: :query, type: :integer, description: "Page number"
        parameter :per_page, in: :query, type: :integer, description: "Items per page"
        response 200, description: "List of users",  schema: { type: :array, items: :User }
        response 401, description: "Unauthorized"
    end

    operation :show do
        summary "Get a user"response 200, description: "User found",     schema: :User
        response 404, description: "User not found"
    end

    operation :create do
        summary "Create a user"response 201, description: "User created",   schema: :User
        response 422, description: "Invalid data"
    end
    
    operation :update do
        summary "Update a user"response 200, description: "User updated",   schema: :User
        response 404, description: "User not found"
        response 422, description: "Invalid data"
    end

    operation :destroy do
        summary "Delete a user"response 200, description: "User deleted"
        response 404, description: "User not found"
    end
end
```

---

## Type Mapping

| ActiveRecord type | OpenAPI type         |
|-------------------|----------------------|
| `integer`         | `integer` / `int32`  |
| `bigint`          | `integer` / `int64`  |
| `float`           | `number` / `float`   |
| `decimal`         | `number` / `double`  |
| `string`          | `string`             |
| `text`            | `string`             |
| `boolean`         | `boolean`            |
| `date`            | `string` / `date`    |
| `datetime`        | `string` / `date-time` |
| `uuid`            | `string` / `uuid`    |
| `json` / `jsonb`  | `object`             |

---

## Auto-reload in Development

OpenapiBlocks watches for changes in:app/openapi//*.rb
app/models//*.rb
config/routes.rb
db/schema.rb

The spec is automatically regenerated on the next request to `/docs/openapi.json` whenever any of these files change. No server restart needed.

---

## Requirements

- Ruby >= 3.2
- Rails >= 7.0

---

## License

[MIT](LICENSE.txt)
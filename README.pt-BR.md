# OpenapiBlocks

OpenapiBlocks é uma gem Rails que gera automaticamente documentação OpenAPI 3.0/3.1 a partir dos seus modelos ActiveRecord, validações do ActiveModel e rotas do Rails, inspirada em [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

Sem anotações manuais. Sem ruído de DSL nos controllers. Basta declarar o que deve ser exposto e o spec é gerado automaticamente.

---

## Instalação

Adicione ao seu `Gemfile`:

```ruby
gem "openapi_blocks"
```

Depois execute:

```bash
bundle install
```

---

## Configuração

### 1. Monte a Engine

```ruby
# config/routes.rb
```

```ruby
Rails.application.routes.draw do
  mount OpenapiBlocks::Engine => "/docs"
  resources :users
end
```

Isso expõe:

<br />
GET /docs/openapi.json

<br />
GET /docs/openapi.yaml

### 2. Configure o initializer

```ruby
# config/initializers/openapi_blocks.rb

OpenapiBlocks.configure do |config|
  config.openapi_version = "3.1" # "3.0" ou "3.1"
  config.info do
    title       "Minha API"
    version     "1.0.0"
    description "Documentação da API gerada automaticamente"
    contact do
      name  "Minha equipe"
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
      description "Produção"
    end
    server do
      url         "http://localhost:3000"
      description "Desenvolvimento"
    end
  end
  config.watch = :development # recarrega automaticamente em mudanças de arquivo
end
```

---

## Uso

### Criando uma classe OpenAPI

Crie um arquivo em `app/openapi/` seguindo a mesma convenção de nomes do ActiveModel::Serializer:

```text
app/
    openapi/
        user_openapi.rb     →  User model
        post_openapi.rb     →  Post model
        order_openapi.rb    →  Order model
```

```ruby
# app/openapi/user_openapi.rb

class UserOpenapi < OpenapiBlocks::Base
  # o model User é inferido automaticamente pelo nome da classe

  # ignora campos sensíveis ou desnecessários
  ignore :password_digest, :reset_password_token

  # associações opt-in
  association :company
  association :posts, type: :array

  # atributos virtuais (não existem no banco)
  attribute :full_name, type: :string
  attribute :token, type: :string, read_only: true
end
```

### O que é gerado automaticamente

Dado este model:

```ruby
class User < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0 }
  validates :role, inclusion: { in: %w[admin user guest] }
end
```

OpenapiBlocks gera:

- `User` schema a partir das colunas e tipos de `db/schema.rb`
- `UserInput` schema para bodies de request de `POST`, `PUT` e `PATCH` (sem `id`, `created_at`, `updated_at`)
- campos `required` a partir de validações `presence: true`
- `minLength` e `maxLength` a partir de validações `length`
- `minimum` e `maximum` a partir de validações `numericality`
- `enum` a partir de validações `inclusion`
- `format: "email"` a partir de validações de formato
- todos os paths a partir de `config/routes.rb`

### Customizando operações

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Base
  operation :index do
    summary     "Listar todos os usuários"
    description "Retorna uma lista paginada de usuários ativos"
    parameter :page,     in: :query, type: :integer, description: "Número da página"
    parameter :per_page, in: :query, type: :integer, description: "Itens por página"
    response 200, description: "Lista de usuários", schema: { type: :array, items: :User }
    response 401, description: "Não autorizado"
  end

  operation :show do
    summary "Buscar um usuário"
    response 200, description: "Usuário encontrado", schema: :User
    response 404, description: "Usuário não encontrado"
  end

  operation :create do
    summary "Criar um usuário"
    response 201, description: "Usuário criado", schema: :User
    response 422, description: "Dados inválidos"
  end

  operation :update do
    summary "Atualizar um usuário"
    response 200, description: "Usuário atualizado", schema: :User
    response 404, description: "Usuário não encontrado"
    response 422, description: "Dados inválidos"
  end

  operation :destroy do
    summary "Excluir um usuário"
    response 200, description: "Usuário excluído"
    response 404, description: "Usuário não encontrado"
  end
end
```

---

## Mapeamento de tipos

| Tipo do ActiveRecord | Tipo OpenAPI            |
|----------------------|-------------------------|
| `integer`            | `integer` / `int32`     |
| `bigint`             | `integer` / `int64`     |
| `float`              | `number` / `float`      |
| `decimal`            | `number` / `double`     |
| `string`             | `string`                |
| `text`               | `string`                |
| `boolean`            | `boolean`               |
| `date`               | `string` / `date`       |
| `datetime`           | `string` / `date-time`  |
| `uuid`               | `string` / `uuid`       |
| `json` / `jsonb`     | `object`                |

---

## Recarregamento automático em desenvolvimento

OpenapiBlocks observa mudanças em:

```text
app/openapi/*.rb
app/models/*.rb
config/routes.rb
db/schema.rb
```

O spec é regenerado automaticamente na próxima requisição para `/docs/openapi.json` sempre que qualquer um desses arquivos muda. Não é necessário reiniciar o servidor.

---

## Requisitos

- Ruby >= 3.2
- Rails >= 7.0

---

## Licença

[MIT](LICENSE.txt)
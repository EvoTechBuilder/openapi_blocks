# OpenapiBlocks

OpenapiBlocks é uma gem Rails que gera automaticamente documentação OpenAPI 3.0/3.1 a partir dos seus modelos ActiveRecord, validações do ActiveModel e rotas do Rails, inspirada em [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

Sem anotações manuais. Sem ruído de DSL nos controllers. Basta declarar o que deve ser exposto e o spec é gerado automaticamente.

## Principais mudanças (recentes)
- Versão padrão do OpenAPI: `3.1.0` (suportado: `3.1.0`, `3.0.3`).
- A Swagger UI é servida no caminho onde a engine foi montada e usa endpoints do mesmo origin (same-origin) para evitar CORS — a UI mostra uma lista de servidores, mas buscará o spec a partir da URL montada.
- A saída YAML é normalizada para chaves em string (`deep_stringify_keys`) para que o campo `openapi` seja reconhecido pelo Swagger UI.
- O DSL `association` usa `read_only: true` para marcar associações como somente resposta e excluí-las dos schemas `*Input`; associações/atributos `read_only` continuam presentes nas respostas.
- O `tags` é gerado no nível do documento a partir dos paths e pode ser customizado via `tags` nas classes e operações.
- Referências de schema aceitam `Symbol` (ex.: `schema: :user`) e arrays com items como símbolos (ex.: `items: :user`).
- O serializer agora inclui atributos `read_only` na saída e teve melhorias de performance em tempo de compilação.

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
  # Versões suportadas: "3.1.0" e "3.0.3". O padrão desta gem é "3.1.0".
  config.openapi_version = "3.1.0" # "3.0.3" ou "3.1.0"
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

Observações:

- A interface Swagger UI fornecida pela engine prioriza a origem atual da
  requisição (same-origin) como servidor primário para evitar problemas de
  CORS ao usar o recurso "Try it out". Você ainda pode listar outros
  servidores em `config.servers` apenas para fins informacionais; a UI
  buscará o documento OpenAPI a partir da URL do spec na mesma origem,
  construída automaticamente com o prefixo usado ao montar a engine.

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
- `UserInput` schema para bodies de request de `POST`, `PUT` e `PATCH` (sem `id`, `created_at`, `updated_at` e atributos virtuais marcados como `read_only`)
- campos `required` a partir de validações `presence: true`
- `minLength` e `maxLength` a partir de validações `length`
- `minimum` e `maximum` a partir de validações `numericality`
- `enum` a partir de validações `inclusion`
- `format: "email"` a partir de validações de formato
- todos os paths a partir de `config/routes.rb`

### Atributos Virtuais

Atributos virtuais são campos que existem apenas na resposta da API e não no banco de dados.

| Opção            | Descrição                                  | Aparece em User | Aparece em UserInput |
| ---------------- | ------------------------------------------ | :-------------: | :------------------: |
| read_only: true  | Campos calculados ou gerados pelo sistema  |       SIM       |         NÃO          |
| read_only: false | Campos que o cliente pode enviar e receber |       SIM       |         SIM          |

```ruby
attribute :full_name,    type: :string, read_only: true   # apenas resposta
attribute :access_token, type: :string, read_only: true   # apenas resposta
attribute :nickname,     type: :string                    # request e response
```

### Customizando operações
```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Base
  tags "Users"

  operation :index do
    summary     "List all users"
    description "Returns a paginated list of active users"
    tags        "Users", "Admin"  # sobrescreve tags em nível de operação

    parameter :page,     in: :query, type: :integer, description: "Page number"
    parameter :per_page, in: :query, type: :integer, description: "Items per page"

    response 200, description: "List of users", schema: { type: :array, items: :User }
    response 401, description: "Unauthorized"
  end

  operation :show do
    summary "Get a user"

    response 200, description: "User found",     schema: :User
    response 404, description: "User not found"
  end

  operation :create do
    summary "Create a user"

    response 201, description: "User created", schema: :User
    response 422, description: "Invalid data"
  end

  operation :update do
    summary "Update a user"

    response 200, description: "User updated",   schema: :User
    response 404, description: "User not found"
    response 422, description: "Invalid data"
  end

  operation :destroy do
    summary "Delete a user"

    response 200, description: "User deleted"
    response 404, description: "User not found"
  end
end
```

## Segurança

Configure esquemas de segurança globais no initializer:

```ruby
config.security do
  bearer_token format: "JWT"                    # Authorization: Bearer <token>
  api_key      name: "X-API-Key", in: :header   # X-API-Key: <key>
end
```

Substitua a segurança por operação:

```ruby
operation :index do
  security :bearerAuth   # apenas bearer nesta operação
end

operation :show do
  no_security!           # endpoint público — sem autenticação
end
```

---

## Associações

```ruby
association :company                             # belongs_to — $ref para Company schema
association :posts, type: :array                 # has_many — array de $ref para Post schema
  association :posts, type: :array, read_only: true   # excluído do UserInput (response only)
```

---

## Atributos Virtuais

Atributos virtuais são campos que existem apenas na resposta da API e não no banco de dados.

| Opção           | Descrição                            | Aparece em User | Aparece em UserInput |
| ---------------- | -------------------------------------- | :-------------: | :------------------: |
| read_only: true  | Campos calculados ou gerados pelo sistema |       SIM       |          NÃO          |
| read_only: false | Campos que o cliente pode enviar e receber |       SIM       |         SIM          |

```ruby
attribute :full_name,    type: :string, read_only: true   # response only
attribute :access_token, type: :string, read_only: true   # response only
attribute :nickname,     type: :string                    # request and response
```

---

## Mapeamento de tipos

| Tipo do ActiveRecord | Tipo OpenAPI            |
|----------------------|-------------------------|
| integer              | integer / int32         |
| bigint               | integer / int64         |
| float                | number / float          |
| decimal              | number / double         |
| string               | string                  |
| text                 | string                  |
| boolean              | boolean                 |
| date                 | string / date           |
| datetime             | string / date-time      |
| uuid                 | string / uuid           |
| json / jsonb         | object                  |

---

## Auto-reload em desenvolvimento

OpenapiBlocks observa mudanças em:

```
app/openapi/**/*.rb
app/models/**/*.rb
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

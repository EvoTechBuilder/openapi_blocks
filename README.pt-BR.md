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
# OpenapiBlocks

OpenapiBlocks é uma gem Rails que gera automaticamente documentação OpenAPI 3.0/3.1 a partir dos seus modelos ActiveRecord, validações do ActiveModel e rotas do Rails — inspirada em ActiveModel::Serializer.

Sem anotações manuais. Sem ruído de DSL nos controllers. Basta declarar o que deve ser exposto e o spec é gerado automaticamente. Inclui um serializer interno de alto desempenho — aproximadamente 3.6× mais rápido que `as_json` com escalabilidade linear consistente.

## Principais mudanças (recentes)
- `OpenapiBlocks::Resource` e `OpenapiBlocks::Controller` foram introduzidos para separar responsabilidades de serialização e documentação.
- Versão padrão do OpenAPI: `3.1.0` (suportado: `3.1.0`, `3.0.3`).
- Scalar UI agora é servido em `/docs/scalar` ao lado da Swagger UI em `/docs`.
- A Swagger UI usa endpoints same-origin para evitar problemas de CORS ao usar "Try it out"; a UI mostra servidores configurados, mas busca o spec a partir da URL montada da engine.
- A saída YAML é normalizada para chaves em string (`deep_stringify_keys`) para que o campo `openapi` seja reconhecido pelo Swagger UI.
- O DSL `association` utiliza `read_only: true` para marcar associações como somente-resposta e excluí-las dos schemas `*Input`; atributos/associações `read_only` continuam presentes em respostas.
- `tags` são gerados no nível do documento a partir dos paths e podem ser customizados via `tags` nas classes e operações.
- Referências de schema aceitam `Symbol` (ex.: `schema: :user`) e arrays com `items` como símbolos (ex.: `items: :user`).
- O serializer compila um método extrator monolítico por classe em tempo de boot usando `class_eval`, eliminando ramificações por objeto e chamadas lambda em tempo de execução.

---

## Instalação

Adicione ao seu Gemfile:

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
Rails.application.routes.draw do
  mount OpenapiBlocks::Engine => "/docs"

  resources :users
end
```

Isso expõe:

```
GET /docs               ->  Scalar UI
GET /docs/swagger       ->  Swagger UI
GET /docs/openapi.json  ->  OpenAPI spec in JSON
GET /docs/openapi.yaml  ->  OpenAPI spec in YAML
```

### 2. Configure o initializer

```ruby
# config/initializers/openapi_blocks.rb
OpenapiBlocks.configure do |config|
  config.openapi_version = "3.1.0"  # "3.0.3" ou "3.1.0"

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

  config.watch = :development  # auto-reload em mudanças de arquivo

  # opcional: esquemas de segurança
  config.security do
    bearer_token format: "JWT"
    api_key      name: "X-API-Key", in: :header
  end
end
```

---

## Uso

OpenapiBlocks fornece duas classes base com responsabilidades distintas:

- `OpenapiBlocks::Resource` — define o model, campos, associações e lógica de serialização.
- `OpenapiBlocks::Controller` — define operações da API, parâmetros e respostas para documentação.
- `OpenapiBlocks::Base` — classe legada que combina ambas as responsabilidades. Ainda suportada.

### Resource + Controller (recomendado)

```
app/
  openapi/
    user_resource.rb    ->  serialização + schema
    user_openapi.rb     ->  documentação da API
    post_resource.rb
    post_openapi.rb
```

```ruby
# app/openapi/user_resource.rb
class UserResource < OpenapiBlocks::Resource
  # o model User é inferido automaticamente pelo nome da classe

  ignore :password_digest, :reset_password_token

  association :posts, type: :array, read_only: true

  attribute :full_name,    type: :string, read_only: true
  attribute :access_token, type: :string, read_only: true
  attribute :nickname,     type: :string

  # método definido aqui — chamado na instância do recurso
  def full_name
    "#{object.name} (#{object.email})"
  end

  # ou omita o método e ele será delegado ao model automaticamente
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

### Base (legado, classe única)

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

O serializer interno compila um método extrator monolítico por classe em tempo de boot usando `class_eval`. Não há loops, nem indirection por lambda e nem ramificações em tempo de execução por objeto.

### Performance (200 registros, arm64, Ruby 4.0)

| Método | i/s | μs/i | vs serialize |
|---|---:|---:|---:|
| serialize | 4 239 | 235 | — |
| to_json | 1 444 | 692 | 2.94× mais lento |
| as_json | 1 186 | 843 | 3.58× mais lento |
| oj+as_json | 1 126 | 888 | 3.77× mais lento |

Escalamento é linear — a vantagem ~3.6× em relação a `as_json` se mantém de 10 a 5000 registros.

### Atributos virtuais e resolução de método

| Declarado com | Método no resource? | Chamada |
|---|---:|---|
| `attribute :full_name` | sim | `resource_instance.full_name` |
| `attribute :full_name` | não | `object.full_name` (delegado ao model) |
| coluna no db | — | `object.full_name` (direto) |

### Resolução de serializer de associação

Para cada associação, a resolução procura na ordem:

1. `PostResource` — se existir `serialize`, é usado diretamente.
2. `PostOpenapi` — se for um `Controller`, delega ao seu `_resource`.
3. Fallback — chama `as_json` no valor da associação.

---

## O que é gerado automaticamente

Dado este model:

```ruby
class User < ApplicationRecord
  validates :name,  presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age,   numericality: { greater_than: 0 }
  validates :role,  inclusion: { in: %w[admin user guest] }
end
```

OpenapiBlocks gera:

- `User` schema a partir de `db/schema.rb` (colunas e tipos)
- `UserInput` schema para bodies de `POST`, `PUT` e `PATCH` (sem `id`, `created_at`, `updated_at` e campos `read_only`)
- `required` a partir de validações `presence: true`
- `minLength` e `maxLength` a partir de validações `length`
- `minimum` e `maximum` a partir de validações `numericality`
- `enum` a partir de validações `inclusion`
- `format: "email"` a partir de validações de formato
- Todos os paths a partir de `config/routes.rb`

---

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
association :company                                  # belongs_to — $ref para Company schema
association :posts, type: :array                      # has_many — array de $ref para Post schema
association :posts, type: :array, read_only: true     # excluído do UserInput (response only)
```

---

## Atributos Virtuais

Atributos virtuais são campos que existem apenas na resposta da API e não no banco de dados.

| Opção | Descrição | Aparece em User | Aparece em UserInput |
|---|---|:---:|:---:|
| `read_only: true` | Campos calculados ou gerados pelo sistema | SIM | NÃO |
| `read_only: false` | Campos que o cliente pode enviar e receber | SIM | SIM |

```ruby
attribute :full_name,    type: :string, read_only: true   # response only
attribute :access_token, type: :string, read_only: true   # response only
attribute :nickname,     type: :string                    # request and response
```

---

## Mapeamento de tipos

| Tipo do ActiveRecord | Tipo OpenAPI |
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

MIT (LICENSE.txt)

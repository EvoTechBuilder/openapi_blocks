# OpenapiBlocks

OpenapiBlocks é uma gem Rails que gera automaticamente documentação OpenAPI 3.0/3.1 a partir dos seus modelos ActiveRecord, validações ActiveModel e rotas Rails — inspirada pelo [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers).

English version: README.md

Sem anotações manuais. Sem ruído de DSL nos controllers. Basta declarar o que expor e a spec é gerada automaticamente. Inclui um serializer próprio de alta performance — ~3.6× mais rápido que `as_json` com escalonamento linear consistente de 10 a 5000 registros.

## Mudanças recentes

- `OpenapiBlocks::Serializer` introduzido para serializers standalone em `app/serializers/` — separando serialização de documentação.
- `OpenapiBlocks::Controller` vincula um serializer à sua documentação via DSL `resource` e `controller`.
- `OpenapiBlocks::Resource` removido — substituído por `OpenapiBlocks::Serializer`.
- `OpenapiBlocks.configure` agora é obrigatório — lança um erro descritivo se `info.title` ou `info.version` estiverem em branco.
- Versão padrão do OpenAPI é `3.1.0` (suportadas: `3.1.0`, `3.0.3`).
- Scalar UI é agora a interface padrão em `/docs`. Swagger UI disponível em `/docs/swagger`.
- DSL `association` usa `read_only: true` para marcar campos como somente-leitura e excluí-los dos schemas `*Input`.
- `tags` são geradas na raiz do documento a partir das rotas e podem ser customizadas via DSL `tags` nas classes e operações.
- Referências de schema aceitam `Symbol` (ex: `schema: :user`) e itens de array podem ser referências simbólicas (ex: `items: :user`).
- O serializer usa `class_eval` para compilar um método extrator monolítico por classe no boot — eliminando branching por objeto, indireção via lambda e checagens de `respond_to?` em runtime.

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
GET /docs/openapi.json  ->  Spec OpenAPI em JSON
GET /docs/openapi.yaml  ->  Spec OpenAPI em YAML
```

### 2. Configure o initializer

`OpenapiBlocks.configure` é obrigatório. A gem lança `OpenapiBlocks::Error` na primeira requisição se nunca foi chamado ou se `info.title` / `info.version` estiverem em branco.

```ruby
# config/initializers/openapi_blocks.rb
OpenapiBlocks.configure do |config|
  config.openapi_version = "3.1.0"  # obrigatório — "3.0.3" ou "3.1.0"

  config.info do
    title       "Minha API"    # obrigatório
    version     "1.0.0"        # obrigatório
    description "Documentação gerada automaticamente"

    contact do
      name  "Meu Time"
      email "api@minhaempresa.com.br"
      url   "https://minhaempresa.com.br"
    end

    license do
      name "MIT"
      url  "https://opensource.org/licenses/MIT"
    end
  end

  config.servers do
    server do
      url         "https://api.minhaempresa.com.br"
      description "Produção"
    end

    server do
      url         "http://localhost:3000"
      description "Desenvolvimento"
    end
  end

  config.watch = :development  # recarrega automaticamente em desenvolvimento

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

- `OpenapiBlocks::Serializer` — define o model, campos, associações e lógica de serialização. Fica em `app/serializers/`.
- `OpenapiBlocks::Controller` — define as operações da API, parâmetros e respostas para documentação. Fica em `app/openapi/`.
- `OpenapiBlocks::Base` — classe base legada que combina ambas as responsabilidades. Ainda suportada.

### Serializer + Controller (recomendado)

```
app/
  serializers/
    user_serializer.rb    ->  serialização + schema
    post_serializer.rb
  openapi/
    user_openapi.rb       ->  documentação da API
    post_openapi.rb
```

```ruby
# app/serializers/user_serializer.rb
class UserSerializer < OpenapiBlocks::Serializer
  # model User é inferido automaticamente pelo nome da classe

  ignore :password_digest, :reset_password_token

  association :posts, type: :array, read_only: true

  attribute :full_name,    type: :string, read_only: true
  attribute :access_token, type: :string, read_only: true
  attribute :nickname,     type: :string

  # método definido aqui — chamado na instância do serializer
  def full_name
    "#{object.name} (#{object.email})"
  end

  # ou omita o método e ele será delegado automaticamente ao model
end
```

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  resource UserSerializer
  controller UsersController

  tags "Usuários"

  operation :index do
    summary     "Lista todos os usuários"
    description "Retorna uma lista paginada de usuários ativos"

    parameter :page,     in: :query, type: :integer, description: "Número da página"
    parameter :per_page, in: :query, type: :integer, description: "Itens por página"

    response 200, description: "Lista de usuários", schema: { type: :array, items: :User }
    response 401, description: "Não autorizado"
  end

  operation :show do
    summary "Busca um usuário"

    response 200, description: "Usuário encontrado", schema: :User
    response 404, description: "Não encontrado"

    no_security!
  end
end
```

```ruby
# app/controllers/users_controller.rb
def index
  render json: UserSerializer.serialize(User.includes(:posts))
end

def show
  render json: UserSerializer.serialize(User.find(params[:id]))
end
```

### Base (legado, classe única)

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Base
  tags "Usuários"

  ignore :password_digest

  association :posts, type: :array, read_only: true

  attribute :full_name, type: :string, read_only: true

  operation :index do
    summary  "Lista todos os usuários"
    response 200, description: "Lista de usuários", schema: { type: :array, items: :User }
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

O serializer embutido compila um método extrator monolítico por classe no boot usando `class_eval`. Sem loops, sem indireção via lambda e sem branching por objeto em runtime.

### Performance (200 registros, arm64, Ruby 4.0)

|            | i/s   | μs/i | vs serialize     |
| ---------- | ----- | ---- | ---------------- |
| serialize  | 4 239 | 235  | —                |
| to_json    | 1 444 | 692  | 2.94× mais lento |
| as_json    | 1 186 | 843  | 3.58× mais lento |
| oj+as_json | 1 126 | 888  | 3.77× mais lento |

O escalonamento é linear — a vantagem de 3.6× sobre `as_json` se mantém de 10 a 5000 registros.

### Atributos virtuais e resolução de métodos

| Declarado com          | Método no serializer? | Chama                                  |
| ---------------------- | --------------------- | -------------------------------------- |
| `attribute :full_name` | sim                   | `serializer_instance.full_name`        |
| `attribute :full_name` | não                   | `object.full_name` (delegado ao model) |
| coluna no banco        | —                     | `object.full_name` (direto)            |

### Resolução do serializer de associações

Para cada associação, o serializer resolve a classe na seguinte ordem:

1. `PostSerializer` — tem `serialize`, usado diretamente.
2. `PostOpenapi` — é um `Controller`, delega para seu `resource`.
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

- Schema `User` a partir das colunas e tipos do `db/schema.rb`
- Schema `UserInput` para corpos de requisição POST, PUT e PATCH (sem `id`, `created_at`, `updated_at` e campos `read_only`)
- Campos `required` a partir de validações `presence: true`
- `minLength`, `maxLength` a partir de validações `length`
- `minimum`, `maximum` a partir de validações `numericality`
- `enum` a partir de validações `inclusion`
- `format: "email"` a partir de validações de formato
- Todos os paths a partir do `config/routes.rb`

---

## Segurança

Configure esquemas de segurança globais no initializer:

```ruby
config.security do
  bearer_token format: "JWT"                    # Authorization: Bearer <token>
  api_key      name: "X-API-Key", in: :header   # X-API-Key: <key>
end
```

Sobrescreva a segurança por operação:

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
association :company                                  # belongs_to — $ref ao schema Company
association :posts, type: :array                      # has_many — array de $ref ao schema Post
association :posts, type: :array, read_only: true     # excluído do UserInput (somente resposta)
```

---

## Atributos Virtuais

Atributos virtuais são campos que existem na resposta da API mas não no banco de dados.

| Opção              | Descrição                                  | Aparece em User | Aparece em UserInput |
| ------------------ | ------------------------------------------ | :-------------: | :------------------: |
| `read_only: true`  | Campos calculados ou gerados pelo sistema  |       SIM       |         NÃO          |
| `read_only: false` | Campos que o cliente pode enviar e receber |       SIM       |         SIM          |

```ruby
attribute :full_name,    type: :string, read_only: true   # somente resposta
attribute :access_token, type: :string, read_only: true   # somente resposta
attribute :nickname,     type: :string                    # requisição e resposta
```

---

## Mapeamento de Tipos

| Tipo ActiveRecord | Tipo OpenAPI       |
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

## Recarregamento Automático em Desenvolvimento

OpenapiBlocks monitora alterações em:

```
app/serializers/**/*.rb
app/openapi/**/*.rb
app/models/**/*.rb
config/routes.rb
db/schema.rb
```

A spec é regenerada automaticamente na próxima requisição a `/docs/openapi.json` sempre que algum desses arquivos mudar. Sem necessidade de reiniciar o servidor.

---

## Requisitos

- Ruby >= 3.2
- Rails >= 7.0

---

## Licença

MIT (LICENSE.txt)

# OpenapiBlocks

OpenapiBlocks é uma gem Rails que gera automaticamente documentação OpenAPI 3.0/3.1 a partir dos seus models ActiveRecord, validações ActiveModel e rotas do Rails — inspirada no ActiveModel::Serializer (https://github.com/rails-api/active_model_serializers).

English version: README.md

Sem anotações manuais. Sem DSL nos controllers. Basta declarar o que expor e a spec é gerada automaticamente. Inclui um serializer de alta performance — ~3.6× mais rápido que as_json com escalabilidade linear de 10 a 5000 registros.

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

## Generators

O OpenapiBlocks oferece três generators para começar rapidamente.

### Install

```bash
rails generate openapi_blocks:install
```

Cria `config/initializers/openapi_blocks.rb` com todas as opções disponíveis comentadas, e monta o engine no `config/routes.rb`:

```ruby
mount OpenapiBlocks::Engine => "/docs"
```

### Openapi

```bash
rails generate openapi_blocks:openapi User
```

Cria `app/openapi/user_openapi.rb` com todas as opções de DSL disponíveis comentadas:

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  # resource UserSerializer
  # controller UsersController

  # tags "Usuários"

  # operation :index do
  #   summary     "Lista todos os usuários"
  #   response 200, description: "Lista de usuários", schema: { type: :array, items: :User }
  # end
end
```

### Serializer

```bash
rails generate openapi_blocks:serializer User
```

Cria `app/serializers/user_serializer.rb` com todas as opções de DSL disponíveis comentadas:

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

## Configuração

### 1. Monte o Engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount OpenapiBlocks::Engine => "/docs"

  resources :users
end
```

Isso expõe:

```
GET /docs               ->  Scalar UI (padrão)
GET /docs/swagger       ->  Swagger UI
GET /docs/openapi.json  ->  Spec OpenAPI em JSON
GET /docs/openapi.yaml  ->  Spec OpenAPI em YAML
```

### 2. Configure o initializer

OpenapiBlocks.configure é obrigatório. A gem lança OpenapiBlocks::Error na primeira requisição se nunca foi chamado ou se info.title / info.version estiverem em branco.

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

  config.watch          = :development  # recarrega automaticamente em desenvolvimento
  config.auto_serialize = true          # opcional — veja Serialização Automática abaixo

  # opcional: esquemas de segurança
  config.security do
    bearer_token format: "JWT"
    api_key      name: "X-API-Key", in: :header
  end
end
```

---

## Uso

O OpenapiBlocks oferece duas classes base com responsabilidades distintas:

- OpenapiBlocks::Serializer — define o model, campos, associações e lógica de serialização. Fica em app/serializers/.
- OpenapiBlocks::Controller — define operações, parâmetros e respostas para documentação. Fica em app/openapi/.
- OpenapiBlocks::Base — classe base legada que combina ambas as responsabilidades. Ainda suportada.

### Recomendado: Serializer + Controller

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
  # model User inferido automaticamente pelo nome da classe

  ignore :password_digest, :reset_password_token

  association :posts, type: :array, read_only: true

  attribute :full_name,    type: :string, read_only: true
  attribute :access_token, type: :string, read_only: true
  attribute :nickname,     type: :string

  # método definido aqui — chamado na instância do serializer
  def full_name
    "#{object.name} (#{object.email})"
  end

  # ou omita o método e ele delega para o model automaticamente
end
```

```ruby
# app/openapi/user_openapi.rb
class UserOpenapi < OpenapiBlocks::Controller
  resource   UserSerializer  # vincula ao serializer — o schema é derivado dele
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

#### Como o schema OpenAPI é gerado

Quando `resource UserSerializer` é declarado em um `Controller`, o OpenapiBlocks deriva o schema OpenAPI diretamente do serializer — não do model. Isso garante que o que está documentado é exatamente o que a API retorna.

O schema é construído a partir de três fontes no serializer:

- Colunas do ActiveRecord — lidas do `db/schema.rb` via o model inferido. Os tipos das colunas são mapeados para tipos OpenAPI automaticamente.
- Declarações `attribute` — campos virtuais que não existem no banco. Campos declarados com `read_only: true` aparecem no schema de resposta `User` mas são excluídos do schema de requisição `UserInput`.
- Declarações `association` — resolvidas como `$ref` para o schema associado. Associações com `read_only: true` aparecem na resposta mas são excluídas do `UserInput`.
- Declarações `ignore` — colunas excluídas de ambos os schemas.

O schema `UserInput` (usado nos request bodies de POST, PUT e PATCH) é derivado automaticamente do schema `User` removendo `id`, `created_at`, `updated_at` e qualquer campo marcado com `read_only: true`.

```ruby
# app/controllers/users_controller.rb
def index
  render json: UserSerializer.serialize(User.includes(:posts))
end

def show
  render json: UserSerializer.serialize(User.find(params[:id]))
end
```

### Legado: Base (classe única)

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

## Serialização Automática

Quando `config.auto_serialize = true`, o OpenapiBlocks intercepta todas as chamadas `render json:` e aplica automaticamente o serializer registrado — sem precisar chamar o serializer explicitamente nos controllers.

```ruby
# config/initializers/openapi_blocks.rb
config.auto_serialize = true
```

```ruby
# app/controllers/users_controller.rb
def index
  render json: User.all  # serializado automaticamente pelo UserSerializer
end

def show
  render json: @user  # serializado automaticamente pelo UserSerializer
end
```

O registro do serializer é automático por convenção (UserSerializer -> User). Para registro explícito:

```ruby
class AdminUserSerializer < OpenapiBlocks::Serializer
  serializes User  # mapeia explicitamente este serializer para o model User
end
```

Se nenhum serializer for encontrado, o OpenapiBlocks usa o comportamento padrão do Rails e registra um aviso no log.

---

## Serializer

O serializer compila um método extrator monolítico por classe no boot usando class_eval. Sem loops, sem indireção via lambda e sem branching por objeto em tempo de execução.

### Performance (200 registros, arm64, Ruby 4.0)

| Método     | i/s   | us/i | vs serialize     |
| ---------- | ----- | ---- | ---------------- |
| serialize  | 4 239 | 235  | —                |
| to_json    | 1 444 | 692  | 2.94× mais lento |
| as_json    | 1 186 | 843  | 3.58× mais lento |
| oj+as_json | 1 126 | 888  | 3.77× mais lento |

A escalabilidade é linear — a vantagem de 3.6× sobre o as_json se mantém de 10 a 5000 registros.

### Atributos virtuais e resolução de métodos

| Declarado com        | Método no serializer? | Chama                                |
| -------------------- | --------------------- | ------------------------------------ |
| attribute :full_name | sim                   | serializer_instance.full_name        |
| attribute :full_name | não                   | object.full_name (delegado ao model) |
| coluna no banco      | —                     | object.attribute (direto)            |

### Resolução do serializer de associações

Para cada associação, o serializer resolve a classe na seguinte ordem:

1. PostSerializer — tem serialize, usado diretamente.
2. PostOpenapi — é um Controller, delega para o \_resource.
3. Fallback — chama as_json no valor da associação.

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

O OpenapiBlocks gera:

- Schema User a partir das colunas e tipos do db/schema.rb
- Schema UserInput para os request bodies de POST, PUT e PATCH (sem id, created_at, updated_at e campos read_only)
- Campos required a partir das validações presence: true
- minLength, maxLength a partir das validações length
- minimum, maximum a partir das validações numericality
- enum a partir das validações inclusion
- format: "email" a partir das validações de formato
- Todos os paths a partir do config/routes.rb

---

## Segurança

Configure esquemas de segurança globais no initializer:

```ruby
config.security do
  bearer_token format: "JWT"                   # Authorization: Bearer <token>
  api_key      name: "X-API-Key", in: :header  # X-API-Key: <key>
end
```

Sobrescreva a segurança por operação:

```ruby
operation :index do
  security :bearerAuth  # só bearer nesta operação
end

operation :show do
  no_security!          # endpoint público — sem autenticação
end
```

---

## Associações

```ruby
association :company                               # belongs_to — $ref para schema Company
association :posts, type: :array                   # has_many — array de $ref para schema Post
association :posts, type: :array, read_only: true  # excluído do UserInput (somente resposta)
```

---

## Atributos Virtuais

Atributos virtuais são campos que existem na resposta da API mas não no banco de dados.

| Opção            | Descrição                                  | Aparece em User | Aparece em UserInput |
| ---------------- | ------------------------------------------ | :-------------: | :------------------: |
| read_only: true  | Campos calculados ou gerados pelo sistema  |       SIM       |         NÃO          |
| read_only: false | Campos que o cliente pode enviar e receber |       SIM       |         SIM          |

```ruby
attribute :full_name,    type: :string, read_only: true  # somente resposta
attribute :access_token, type: :string, read_only: true  # somente resposta
attribute :nickname,     type: :string                   # requisição e resposta
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

O OpenapiBlocks monitora mudanças em:

```
app/serializers/**/*.rb
app/openapi/**/*.rb
app/models/**/*.rb
config/routes.rb
db/schema.rb
```

A spec é regenerada automaticamente na próxima requisição a /docs/openapi.json sempre que algum desses arquivos for alterado. Sem precisar reiniciar o servidor.

---

## Requisitos

- Ruby >= 3.2
- Rails >= 7.0

---

## Licença

MIT (LICENSE.txt)

# frozen_string_literal: true

module OpenapiBlocks
  module Schema
    module Types # rubocop:disable Style/Documentation
      MAPPING = {
        # Inteiros
        "integer"   => { type: "integer", format: "int32" },
        "bigint"    => { type: "integer", format: "int64" },
        "smallint"  => { type: "integer" },

        # Decimais
        "float"     => { type: "number", format: "float" },
        "decimal"   => { type: "number", format: "double" },

        # Texto
        "string"    => { type: "string" },
        "text"      => { type: "string" },
        "citext"    => { type: "string" },

        # Booleano
        "boolean"   => { type: "boolean" },

        # Datas e horas
        "date"      => { type: "string", format: "date" },
        "datetime"  => { type: "string", format: "date-time" },
        "timestamp" => { type: "string", format: "date-time" },
        "time"      => { type: "string", format: "time" },

        # UUID
        "uuid"      => { type: "string", format: "uuid" },

        # JSON
        "json"      => { type: "object" },
        "jsonb"     => { type: "object" },

        # Binário
        "binary"    => { type: "string", format: "binary" },

        # Arrays (PostgreSQL)
        "string[]"  => { type: "array", items: { type: "string" } },
        "integer[]" => { type: "array", items: { type: "integer" } }
      }.freeze

      DEFAULT = { type: "string" }.freeze

      def self.map(ar_type)
        MAPPING.fetch(ar_type.to_s, DEFAULT)
      end
    end
  end
end

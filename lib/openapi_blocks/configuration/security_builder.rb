# frozen_string_literal: true

module OpenapiBlocks
  class Configuration
    class SecurityBuilder # rubocop:disable Style/Documentation
      attr_reader :schemes

      def initialize
        @schemes = {}
      end

      def bearer_token(format: "JWT")
        @schemes[:bearerAuth] = {
          type:         "http",
          scheme:       "bearer",
          bearerFormat: format
        }
      end

      def api_key(name: "X-API-Key", in: :header)
        @schemes[:apiKey] = {
          type: "apiKey",
          name: name,
          in:   binding.local_variable_get(:in).to_s
        }
      end

      def to_h
        @schemes
      end
    end
  end
end

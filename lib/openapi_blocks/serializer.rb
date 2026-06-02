# frozen_string_literal: true

module OpenapiBlocks
  class Serializer # rubocop:disable Style/Documentation
    include Concerns::Schemable
    include Serialization

    class << self
      private

      def serialization_sentinel = OpenapiBlocks::Serializer

      def infer_model
        model_name = name
                     .gsub(/Serializer$/, "")
                     .split("::").last
        Object.const_get(model_name)
      rescue NameError
        raise Error, "Could not infer model from #{name}. Use `model ModelClass` to define it explicitly."
      end
    end
  end
end

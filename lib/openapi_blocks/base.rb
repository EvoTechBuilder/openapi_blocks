# frozen_string_literal: true

module OpenapiBlocks
  # <b>DEPRECATED:</b> please use <tt>OpenapiBlocks::Controllers</tt> and <tt>OpenapiBlocks::Resources</tt> instead.
  class Base
    include Concerns::Schemable
    include Concerns::Documentable
    include Serialization

    class << self
      private

      def infer_model
        model_name = name
                     .gsub(/Openapi$/, "")
                     .gsub(/Serializer$/, "")
                     .split("::")
                     .last

        Object.const_get(model_name)
      rescue NameError
        raise Error, "Could not infer model from #{name}. Use `model ModelClass` to define it explicitly."
      end
    end
  end
end

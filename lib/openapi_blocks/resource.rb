# frozen_string_literal: true

module OpenapiBlocks
  class Resource < Base # rubocop:disable Style/Documentation
    class << self
      private

      def infer_model
        model_name = name
                     .gsub(/Resource$/, "")
                     .split("::")
                     .last

        Object.const_get(model_name)
      rescue NameError
        raise Error, "Could not infer model from #{name}. Use `model ModelClass` to define it explicitly."
      end
    end
  end
end

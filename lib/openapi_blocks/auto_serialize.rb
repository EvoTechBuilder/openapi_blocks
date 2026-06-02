# frozen_string_literal: true

module OpenapiBlocks
  module AutoSerialize # rubocop:disable Style/Documentation
    def render(options = nil, extra = nil, &) # rubocop:disable Metrics/MethodLength
      if auto_serialize_candidate?(options)
        object     = options[:json]
        serializer = Registry.resolve(object)

        if serializer
          log_serializer(object, serializer)
          options = options.merge(json: serializer.serialize(object))
        else
          warn_no_serializer(object)
        end
      end

      super
    end

    private

    def auto_serialize_candidate?(options)
      OpenapiBlocks.configuration.auto_serialize &&
        options.is_a?(Hash) &&
        options.key?(:json)
    end

    def log_serializer(object, serializer)
      model = extract_model(object)
      Rails.logger.debug(
        "[OpenapiBlocks] #{model.name} serialized by #{serializer.name}"
      )
    end

    def warn_no_serializer(object)
      model = extract_model(object)
      return unless model

      Rails.logger.warn(
        "[OpenapiBlocks] No serializer found for #{model.name}. " \
        "Falling back to default Rails rendering. " \
        "Create #{model.name}Serializer or use `serializes #{model.name}` explicitly."
      )
    end

    def extract_model(object)
      case object
      when Array then object.first&.class
      else object.respond_to?(:klass) ? object.klass : object.class
      end
    end
  end
end

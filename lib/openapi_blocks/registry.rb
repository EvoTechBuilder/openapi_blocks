# frozen_string_literal: true

module OpenapiBlocks
  module Registry # rubocop:disable Style/Documentation
    @map = {}
    @mutex = Mutex.new

    class << self
      def register(model, serializer)
        @mutex.synchronize { @map[model] = serializer }
      end

      def resolve(object)
        model = extract_model(object)
        @mutex.synchronize { @map[model] }
      end

      def build!
        @mutex.synchronize { @map = {} }

        # Passagem 1 — convenção de nome a partir dos serializers carregados
        ObjectSpace.each_object(Class).each do |klass|
          next unless safe_serializer?(klass)

          model_name = Module.instance_method(:name).bind_call(klass)
                             &.gsub(/Serializer$/, "")
                             &.split("::")
                             &.last
          next if model_name.blank?

          model = Object.const_get(model_name)
          next unless model < ActiveRecord::Base

          register(model, klass)
        rescue NameError
          next
        end

        ObjectSpace.each_object(Class).each do |klass|
          next unless safe_serializer?(klass)
          next unless klass.respond_to?(:_serializes) && klass._serializes&.any?

          klass._serializes.each { |model| register(model, klass) }
        end
      end

      def reset!
        @mutex.synchronize { @map = {} }
      end

      private

      def safe_serializer?(klass)
        name = Module.instance_method(:name).bind_call(klass)
        name&.end_with?("Serializer") && klass < OpenapiBlocks::Serializer
      rescue StandardError
        false
      end

      def extract_model(object)
        case object
        when Array
          object.first&.class
        else
          object.respond_to?(:klass) ? object.klass : object.class
        end
      end
    end
  end
end

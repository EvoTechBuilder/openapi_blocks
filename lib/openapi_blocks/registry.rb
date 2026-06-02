# frozen_string_literal: true

module OpenapiBlocks
  module Registry # rubocop:disable Style/Documentation
    @map   = {}
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

        serializer_classes.each do |klass|
          register_by_convention(klass)
          register_by_explicit(klass)
        end
      end

      def reset!
        @mutex.synchronize { @map = {} }
      end

      private

      def serializer_classes
        ObjectSpace.each_object(Class).select { |klass| safe_serializer?(klass) }
      end

      def register_by_convention(klass)
        model_name = klass_name(klass)
                     .gsub(/Serializer$/, "")
                     &.split("::")
                     &.last
        return if model_name.blank?

        model = Object.const_get(model_name)
        return unless model < ActiveRecord::Base

        register(model, klass)
      rescue NameError
        nil
      end

      def register_by_explicit(klass)
        return unless klass.respond_to?(:_serializes) && klass._serializes&.any?

        klass._serializes.each { |model| register(model, klass) }
      end

      def safe_serializer?(klass)
        klass_name(klass)&.end_with?("Serializer") && klass < OpenapiBlocks::Serializer
      rescue StandardError
        false
      end

      def klass_name(klass)
        Module.instance_method(:name).bind_call(klass)
      end

      def extract_model(object)
        case object
        when Array then object.first&.class
        else            object.respond_to?(:klass) ? object.klass : object.class
        end
      end
    end
  end
end

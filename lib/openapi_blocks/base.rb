# frozen_string_literal: true

module OpenapiBlocks
  class Base # rubocop:disable Style/Documentation
    class << self
      attr_reader :_model, :_ignored, :_associations, :_virtual_attributes, :_operations, :_tags

      def model(klass = nil)
        klass ? @_model = klass : @_model ||= infer_model # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def ignore(*attributes)
        @_ignored ||= []
        @_ignored.concat(attributes.map(&:to_s))
      end

      def association(name, type: nil, read_only: false)
        @_associations ||= []
        @_associations << { name: name, type: type, read_only: read_only }
      end

      def attribute(name, **)
        @_virtual_attributes ||= []
        @_virtual_attributes << ({ name: name, ** })
      end

      def operation(action, &block)
        @_operations ||= {}
        builder = OperationBuilder.new
        builder.instance_eval(&block) if block
        @_operations[action] = builder
      end

      def tags(*values)
        values.any? ? @_tags = values : @_tags
      end

      private

      def infer_model
        model_name = name
                     .gsub(/Openapi$/, "")
                     .split("::")
                     .last

        Object.const_get(model_name)
      rescue NameError
        raise Error, "Could not infer model from #{name}. Use `model ModelClass` to define it explicitly."
      end
    end
  end
end

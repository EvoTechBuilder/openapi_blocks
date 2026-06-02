# frozen_string_literal: true

module OpenapiBlocks
  class Controller # rubocop:disable Style/Documentation
    class << self
      attr_reader :_resource, :_operations, :_tags, :_controller_class

      def resource(klass)
        @_resource = klass
      end

      def controller(klass)
        @_controller_class = klass
      end

      def model
        @_resource&.model
      end

      def _associations
        @_resource&._associations
      end

      def _virtual_attributes
        @_resource&._virtual_attributes
      end

      def _ignored
        @_resource&._ignored
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
    end
  end
end

# frozen_string_literal: true

module OpenapiBlocks
  module Concerns
    module Documentable # rubocop:disable Style/Documentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # rubocop:disable Style/Documentation
        attr_reader :_operations, :_tags

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
end

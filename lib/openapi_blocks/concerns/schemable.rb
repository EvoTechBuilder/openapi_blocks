# frozen_string_literal: true

module OpenapiBlocks
  module Concerns
    module Schemable # rubocop:disable Style/Documentation
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods # rubocop:disable Style/Documentation
        attr_reader :_model, :_ignored, :_associations, :_virtual_attributes, :_serializes

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
          @_virtual_attributes << { name: name, ** }
        end

        def serializes(*models)
          @_serializes ||= []
          @_serializes.concat(models)
        end

        private

        def infer_model
          raise NotImplementedError, "#{name} must implement infer_model"
        end
      end
    end
  end
end

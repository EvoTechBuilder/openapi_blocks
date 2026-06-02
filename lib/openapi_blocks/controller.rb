# frozen_string_literal: true

module OpenapiBlocks
  class Controller # rubocop:disable Style/Documentation
    include Concerns::Documentable

    class << self
      attr_reader :_resource, :_controller_class

      def resource(klass)
        @_resource = klass
      end

      def controller(klass)
        @_controller_class = klass
      end

      def model               = @_resource&.model
      def _associations       = @_resource&._associations
      def _virtual_attributes = @_resource&._virtual_attributes
      def _ignored            = @_resource&._ignored
    end
  end
end

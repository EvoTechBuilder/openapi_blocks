# frozen_string_literal: true

module OpenapiBlocks
  module Serializer # rubocop:disable Style/Documentation
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods # rubocop:disable Metrics/ModuleLength,Style/Documentation
      def serialize(resource, instance: nil) # rubocop:disable Lint/UnusedMethodArgument
        extractor = compiled_extractor
        if resource.respond_to?(:each)
          resource.map { |r| extractor.call(r) }
        else
          extractor.call(resource)
        end
      end

      def to_json(resource)
        Oj.dump(serialize(resource), mode: :compat)
      end

      def fields
        @fields ||= resolve_fields
      end

      def compiled_extractor
        @compiled_extractor ||= build_compiled_extractor
      end

      private

      def build_compiled_extractor # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        classified = classify_fields

        model_lines     = classified[:model].map     { |f| %("#{f}" => object.public_send(:#{f})) }
        virtual_lines   = classified[:virtual].map   { |f| %("#{f}" => inst.public_send(:#{f})) }
        delegated_lines = classified[:delegated].map { |f| %("#{f}" => object.public_send(:#{f})) }
        assoc_lines     = classified[:association].map do |f|
          %("#{f}" => _serialize_assoc_#{f}(object))
        end

        classified[:association].each { |field| build_assoc_method(field) }

        all_lines = (model_lines + delegated_lines + virtual_lines + assoc_lines).join(",\n        ")

        if classified[:virtual].any?
          serializer_klass = self
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
            def self._extract(object)
              inst = #{serializer_klass}.new(object)
              {
                #{all_lines}
              }
            end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
            def self._extract(object)
              {
                #{all_lines}
              }
            end
          RUBY
        end

        method(:_extract)
      end

      def build_assoc_method(field) # rubocop:disable Metrics/MethodLength
        assoc = assoc_metadata_by_name[field]
        assoc_name    = assoc[:name]
        serializer    = resolve_assoc_serializer(assoc_name)

        if serializer.nil?
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
            def self._serialize_assoc_#{field}(object)
              object.public_send(:#{assoc_name}).as_json
            end
          RUBY
          return
        end

        if assoc[:type] == :array
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
            def self._serialize_assoc_#{field}(object)
              val = object.public_send(:#{assoc_name})
              return nil if val.nil?
              val.map { |v| #{serializer}.serialize(v) }
            end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1) # rubocop:disable Style/DocumentDynamicEvalDefinition
            def self._serialize_assoc_#{field}(object)
              val = object.public_send(:#{assoc_name})
              val.nil? ? nil : #{serializer}.serialize(val)
            end
          RUBY
        end
      end

      def resolve_assoc_serializer(assoc_name)
        classified = assoc_name.to_s.classify

        ["#{classified}Resource", "#{classified}Openapi"].each do |name|
          klass = Object.const_get(name)
          return klass._resource if klass.respond_to?(:_resource) && klass._resource
          return klass           if klass.respond_to?(:serialize)
        rescue NameError
          next
        end

        nil
      end

      def classify_fields # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        model_set = Set.new(resolve_model_fields)
        assoc_set   = Set.new(assoc_metadata_by_name.keys)
        virtual_set = Set.new(
          Array(_virtual_attributes).map { |a| a[:name].to_s }
        )

        result = { model: [], virtual: [], delegated: [], association: [] }
        fields.each do |field|
          result[if assoc_set.include?(field)
                   :association
                 elsif model_set.include?(field)
                   :model
                 elsif virtual_set.include?(field) && method_defined?(field.to_sym)
                   :virtual       # método definido no resource
                 elsif virtual_set.include?(field)
                   :delegated     # método definido no model
                 else # rubocop:disable Lint/DuplicateBranch
                   :delegated
                 end] << field
        end
        result
      end

      def assoc_metadata_by_name
        @assoc_metadata_by_name ||= begin
          klass  = self
          result = {}
          while klass && klass != OpenapiBlocks::Base
            Array(klass._associations)
              .each { |a| result[a[:name].to_s] ||= a }
            klass = klass.superclass
          end
          result
        end
      end

      def resolve_fields # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        klass = self

        model_fields   = resolve_model_fields
        virtual_fields = []
        ignored_fields = []
        assoc_fields   = []

        while klass && klass != OpenapiBlocks::Base
          virtual_fields += Array(klass._virtual_attributes)
                            .map    { |a| a[:name].to_s }
          ignored_fields += Array(klass._ignored)
          assoc_fields   += Array(klass._associations)
                            .map    { |a| a[:name].to_s }
          klass = klass.superclass
        end

        (model_fields + virtual_fields + assoc_fields - ignored_fields).uniq
      end

      def resolve_model_fields
        klass = self
        while klass && klass != OpenapiBlocks::Base
          begin
            return klass.model.column_names
          rescue StandardError
            klass = klass.superclass
          end
        end
        []
      end
    end

    attr_reader :object, :parent

    def initialize(object, parent = nil)
      @object = object
      @parent = parent
    end
  end
end

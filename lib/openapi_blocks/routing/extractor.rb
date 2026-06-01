# frozen_string_literal: true

require_relative "operation"

module OpenapiBlocks
  module Routing
    class Extractor # rubocop:disable Style/Documentation,Metrics/ClassLength
      IGNORED_CONTROLLERS = %w[
        rails/
        action_mailbox/
        active_storage/
        openapi_blocks/
      ].freeze

      def initialize(app = Rails.application)
        @app = app
      end

      def extract
        routes.each_with_object({}) do |operation, hash|
          next unless operation.valid?

          hash[operation.path] ||= {}

          operation.verbs.each do |verb|
            hash[operation.path][verb] = build_operation(operation)
          end
        end
      end

      private

      def routes
        @app.routes.routes.filter_map do |route|
          defaults = route.defaults
          next unless defaults[:controller] && defaults[:action]
          next if IGNORED_CONTROLLERS.any? { |c| defaults[:controller].start_with?(c) }

          Operation.new(
            controller: defaults[:controller],
            action:     defaults[:action],
            path:       route.path.spec.to_s
          )
        end
      end

      def build_operation(operation) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        meta = operation_meta(operation)

        op = {
          tags:        [operation.schema_name],
          summary:     meta&._summary || build_summary(operation),
          operationId: build_operation_id(operation),
          responses:   meta&._responses ? build_custom_responses(meta) : build_default_responses(operation)
        }

        op[:description] = meta._description if meta&._description
        op[:parameters]  = build_parameters(operation, meta) if build_parameters(operation, meta).any?
        op[:requestBody] = build_request_body(operation)     if operation.has_body

        op
      end

      def build_summary(operation)
        "#{operation.action.humanize} #{operation.schema_name}"
      end

      def build_operation_id(operation)
        "#{operation.action}#{operation.schema_name}"
      end

      def build_parameters(operation, meta)
        params = build_path_parameters(operation)
        params += build_query_parameters(meta) if meta&._parameters
        params
      end

      def build_path_parameters(operation)
        operation.path_parameters.map do |param|
          {
            name:     param,
            in:       "path",
            required: true,
            schema:   { type: "string" }
          }
        end
      end

      def build_query_parameters(meta)
        meta._parameters.map do |param|
          {
            name:        param[:name],
            in:          param[:in].to_s,
            required:    param[:required] || false,
            description: param[:description],
            schema:      { type: param[:type].to_s }
          }.compact
        end
      end

      def build_default_responses(operation) # rubocop:disable Metrics/MethodLength
        status = operation.action == "create" ? "201" : "200"
        ref    = { "$ref" => "#/components/schemas/#{operation.schema_name}" }

        responses = {
          status => {
            description: "#{operation.action.humanize} #{operation.schema_name}",
            content:     {
              "application/json" => {
                schema: operation.action == "index" ? { type: "array", items: ref } : ref
              }
            }
          }
        }

        responses["422"] = { description: "Unprocessable entity" } if operation.has_body
        responses["404"] = { description: "Not found" }            if %w[show update destroy].include?(operation.action)

        responses
      end

      def build_custom_responses(meta)
        meta._responses.each_with_object({}) do |(status, response), hash|
          hash[status.to_s] = build_response_object(response)
        end
      end

      def build_response_object(response)
        obj = { description: response[:description] }
        return obj unless response[:schema]

        obj[:content] = {
          "application/json" => {
            schema: resolve_schema(response[:schema])
          }
        }
        obj
      end

      def resolve_schema(schema)
        case schema
        in { type: :array, items: Symbol => ref }
          { type: "array", items: { "$ref" => "#/components/schemas/#{ref}" } }
        in Symbol => ref
          { "$ref" => "#/components/schemas/#{ref}" }
        else
          schema
        end
      end

      def build_request_body(operation)
        ref = { "$ref" => "#/components/schemas/#{operation.schema_name}Input" }

        {
          required: true,
          content:  {
            "application/json" => { schema: ref }
          }
        }
      end

      def operation_meta(operation)
        openapi_class = find_openapi_class(operation)
        openapi_class&._operations&.dig(operation.action.to_sym)
      end

      def find_openapi_class(operation)
        openapi_name = "#{operation.schema_name}Openapi"

        ObjectSpace.each_object(Class).find do |klass|
          klass < OpenapiBlocks::Base && klass.name == openapi_name
        end
      end
    end
  end
end

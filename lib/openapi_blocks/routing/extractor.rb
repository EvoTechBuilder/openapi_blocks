# frozen_string_literal: true

require_relative "operation"

module OpenapiBlocks
  module Routing
    class Extractor # rubocop:disable Style/Documentation
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

      def build_operation(operation)
        op = {
          tags:        [operation.schema_name],
          summary:     build_summary(operation),
          operationId: build_operation_id(operation),
          responses:   build_responses(operation)
        }

        op[:parameters]  = build_path_parameters(operation) if operation.path_parameters.any?
        op[:requestBody] = build_request_body(operation)    if operation.has_body

        op
      end

      def build_summary(operation)
        "#{operation.action.humanize} #{operation.schema_name}"
      end

      def build_operation_id(operation)
        "#{operation.action}#{operation.schema_name}"
      end

      def build_responses(operation) # rubocop:disable Metrics/MethodLength
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

      def build_request_body(operation)
        ref = { "$ref" => "#/components/schemas/#{operation.schema_name}Input" }

        {
          required: true,
          content:  {
            "application/json" => { schema: ref }
          }
        }
      end
    end
  end
end

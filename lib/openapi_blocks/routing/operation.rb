# frozen_string_literal: true

module OpenapiBlocks
  module Routing
    class Operation # rubocop:disable Style/Documentation
      ACTIONS_MAP = {
        "index"   => { verbs: ["get"], has_body: false },
        "show"    => { verbs: ["get"],           has_body: false },
        "create"  => { verbs: ["post"],          has_body: true  },
        "update"  => { verbs: %w[put patch], has_body: true },
        "destroy" => { verbs: ["delete"], has_body: false }
      }.freeze

      attr_reader :verbs, :path, :action, :controller, :has_body

      def initialize(route)
        @controller = route[:controller]
        @action     = route[:action]
        @path       = normalize_path(route[:path])
        @verbs      = ACTIONS_MAP.dig(@action, :verbs)
        @has_body   = ACTIONS_MAP.dig(@action, :has_body)
      end

      def valid?
        ACTIONS_MAP.key?(@action) && @verbs.present?
      end

      def path_parameters
        @path.scan(/\{(\w+)\}/).flatten
      end

      def schema_name
        @controller.split("/").last.classify
      end

      private

      def normalize_path(path)
        path
          .gsub("(.:format)", "")
          .gsub(/:(\w+)/, '{\1}')
      end
    end
  end
end

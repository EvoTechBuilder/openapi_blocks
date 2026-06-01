# frozen_string_literal: true

require_relative "../routing/extractor"

module OpenapiBlocks
  module Spec
    class Paths # rubocop:disable Style/Documentation
      def initialize(app = Rails.application)
        @app = app
      end

      def build
        Routing::Extractor.new(@app).extract
      end
    end
  end
end

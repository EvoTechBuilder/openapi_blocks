# frozen_string_literal: true

module OpenapiBlocks
  class Configuration
    class ServerBuilder # rubocop:disable Style/Documentation
      def url(value = nil)
        value ? @url = value : @url
      end

      def description(value = nil)
        value ? @description = value : @description
      end

      def to_h
        { url: @url, description: @description }.compact
      end
    end
  end
end

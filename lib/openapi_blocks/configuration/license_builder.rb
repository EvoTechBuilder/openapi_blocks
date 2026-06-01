# frozen_string_literal: true

module OpenapiBlocks
  class Configuration
    class LicenseBuilder # rubocop:disable Style/Documentation
      def name(value = nil)
        value ? @name = value : @name
      end

      def url(value = nil)
        value ? @url = value : @url
      end

      def to_h
        { name: @name, url: @url }.compact
      end
    end
  end
end

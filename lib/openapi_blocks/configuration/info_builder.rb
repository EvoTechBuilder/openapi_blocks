# frozen_string_literal: true

require_relative "contact_builder"
require_relative "license_builder"

module OpenapiBlocks
  class Configuration
    class InfoBuilder # rubocop:disable Style/Documentation
      def title(value = nil)
        value ? @title = value : @title
      end

      def version(value = nil)
        value ? @version = value : @version
      end

      def description(value = nil)
        value ? @description = value : @description
      end

      def contact(&block)
        @contact = ContactBuilder.new
        @contact.instance_eval(&block) if block
      end

      def license(&block)
        @license = LicenseBuilder.new
        @license.instance_eval(&block) if block
      end

      def to_h
        {
          title:       @title,
          version:     @version,
          description: @description,
          contact:     @contact&.to_h,
          license:     @license&.to_h
        }.compact
      end
    end
  end
end

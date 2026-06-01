# frozen_string_literal: true

require_relative "server_builder"

module OpenapiBlocks
  class Configuration
    class ServersBuilder # rubocop:disable Style/Documentation
      attr_reader :servers

      def initialize
        @servers = []
      end

      def server(&block)
        s = ServerBuilder.new
        s.instance_eval(&block) if block
        @servers << s
      end
    end
  end
end

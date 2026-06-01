# frozen_string_literal: true

module OpenapiBlocks
  class SpecController < ActionController::API # rubocop:disable Style/Documentation
    def show
      spec = OpenapiBlocks::Builder.build

      if request.format.yaml?
        render plain: spec.to_yaml, content_type: "application/yaml"
      else
        render json: spec
      end
    end
  end
end

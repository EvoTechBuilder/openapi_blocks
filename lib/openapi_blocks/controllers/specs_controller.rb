# frozen_string_literal: true

module OpenapiBlocks
  class SpecsController < ActionController::API # rubocop:disable Style/Documentation
    def show
      spec = OpenapiBlocks::Builder.build

      respond_to do |format|
        format.json { render json: spec }
        format.yaml { render plain: spec.to_yaml, content_type: "application/yaml" }
      end
    end
  end
end

# frozen_string_literal: true

module OpenapiBlocks
  class OperationBuilder # rubocop:disable Style/Documentation
    attr_reader :_summary, :_description, :_parameters, :_responses

    def summary(value = nil)
      value ? @_summary = value : @_summary
    end

    def description(value = nil)
      value ? @_description = value : @_description
    end

    def parameter(name, in:, type:, description: nil, required: false)
      @_parameters ||= []
      @_parameters << {
        name:        name,
        in:          binding.local_variable_get(:in),
        type:        type,
        description: description,
        required:    required
      }.compact
    end

    def response(status, description:, schema: nil)
      @_responses ||= {}
      @_responses[status.to_s] = {
        description: description,
        schema:      schema
      }.compact
    end

    def to_h
      {
        summary:     @_summary,
        description: @_description,
        parameters:  @_parameters,
        responses:   @_responses
      }.compact
    end
  end
end

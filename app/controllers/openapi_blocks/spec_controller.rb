# frozen_string_literal: true

require "action_controller/api"

module OpenapiBlocks
  class SpecController < ActionController::API # rubocop:disable Style/Documentation,Metrics/ClassLength
    SWAGGER_UI_CSS             = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css"
    SWAGGER_UI_STANDALONE_JS   = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"
    SWAGGER_UI_JS              = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"
    SCALAR_JS                  = "https://cdn.jsdelivr.net/npm/@scalar/api-reference"

    def ui
      render html: swagger_ui_html.html_safe
    end

    def scalar
      render html: scalar_html.html_safe
    end

    def show
      spec = OpenapiBlocks::Builder.build.deep_stringify_keys
      spec["servers"] = swagger_ui_servers(spec)

      if request.format.yaml?
        render plain: spec.to_yaml, content_type: "application/yaml"
      else
        render json: spec
      end
    end

    private

    def scalar_html # rubocop:disable Metrics/MethodLength
      spec_url = "#{swagger_spec_base_url}.json"
      title    = "#{OpenapiBlocks.configuration.info.title} - Scalar"

      <<~HTML
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>#{title}</title>
          </head>
          <body>
            <script
              id="api-reference"
              data-url="#{spec_url}"
              data-configuration='#{scalar_configuration.to_json}'
            ></script>
            <script src="#{SCALAR_JS}"></script>
          </body>
        </html>
      HTML
    end

    def scalar_configuration
      {
        theme:                  "default",
        layout:                 "modern",
        displayRequestDuration: true,
        defaultHttpClient:      {
          targetKey: "ruby",
          clientKey: "net_http"
        }
      }
    end

    def swagger_ui_html # rubocop:disable Metrics/MethodLength
      urls = swagger_ui_urls

      <<~HTML
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>#{swagger_ui_title}</title>
            <link rel="stylesheet" href="#{SWAGGER_UI_CSS}" />
            <style>
              html, body { margin: 0; padding: 0; height: 100%; background: #f6f7fb; }
              #swagger-ui { height: 100%; }
            </style>
          </head>
          <body>
            <div id="swagger-ui"></div>
            <script src="#{SWAGGER_UI_JS}"></script>
            <script src="#{SWAGGER_UI_STANDALONE_JS}"></script>
            <script>
              window.ui = SwaggerUIBundle({
                urls: #{urls.to_json},
                'urls.primaryName': #{urls.first[:name].to_json},
                dom_id: '#swagger-ui',
                deepLinking: true,
                displayRequestDuration: true,
                docExpansion: 'list',
                presets: [
                  SwaggerUIBundle.presets.apis,
                  SwaggerUIStandalonePreset
                ],
                layout: 'StandaloneLayout'
              });
            </script>
          </body>
        </html>
      HTML
    end

    def swagger_ui_title
      "#{OpenapiBlocks.configuration.info.title} - SwaggerUI"
    end

    def swagger_ui_urls
      spec_base = swagger_spec_base_url
      servers   = OpenapiBlocks.configuration.to_h[:servers]

      return default_swagger_ui_urls if servers.blank?

      servers.flat_map do |server|
        [
          { url: "#{spec_base}.json", name: "#{server[:url]} JSON" },
          { url: "#{spec_base}.yaml", name: "#{server[:url]} YAML" }
        ]
      end
    end

    def default_swagger_ui_urls
      spec_base = swagger_spec_base_url

      [
        { url: "#{spec_base}.json", name: "OpenAPI JSON" },
        { url: "#{spec_base}.yaml", name: "OpenAPI YAML" }
      ]
    end

    def swagger_spec_base_url
      mount_path = request.script_name.to_s.chomp("/")
      mount_path.present? ? "#{mount_path}/openapi" : "/openapi"
    end

    def swagger_ui_servers(_spec)
      [{ "url" => request.base_url, "description" => "Current" }]
    end
  end
end

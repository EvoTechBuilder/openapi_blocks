# frozen_string_literal: true

require "action_controller/api"

module OpenapiBlocks
  class SpecController < ActionController::API # rubocop:disable Style/Documentation
    SWAGGER_UI_CSS = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css"
    SWAGGER_UI_STANDALONE_JS = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js"
    SWAGGER_UI_JS = "https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js"
    SWAGGER_UI_TITLE = "#{OpenapiBlocks.configuration.info.title} - SwaggerUI".freeze

    def ui
      render html: swagger_ui_html.html_safe
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

    def swagger_ui_html
      urls = swagger_ui_urls

      <<~HTML
        <!doctype html>
        <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>#{SWAGGER_UI_TITLE}</title>
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

    def swagger_ui_urls
      spec_base = swagger_spec_base_url
      servers = OpenapiBlocks.configuration.to_h[:servers]

      return default_swagger_ui_urls if servers.blank?

      servers.flat_map do |server|
        [
          {
            url:  "#{spec_base}.json",
            name: "#{server[:url]} JSON"
          },
          {
            url:  "#{spec_base}.yaml",
            name: "#{server[:url]} YAML"
          }
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

    def swagger_ui_servers(spec)
      servers = Array(spec["servers"])
      current_origin = { "url" => request.base_url, "description" => "Current" }

      return [current_origin] if servers.empty?

      [current_origin]
    end
  end
end

module Postnhost
  module Api
    module V1
      class McpController < Api::BaseController
        before_action :validate_transport!

        def create
          message = JSON.parse(request.raw_post)
          unless message.is_a?(Hash)
            render json: { jsonrpc: "2.0", id: nil, error: { code: -32_600, message: "Invalid Request" } }, status: :bad_request
            return
          end
          result = Management::Mcp.new(user: api_user, script_name: request.script_name).call(message)
          result ? render(json: result) : head(:accepted)
        rescue JSON::ParserError
          render json: { jsonrpc: "2.0", id: nil, error: { code: -32_700, message: "Parse error" } }, status: :bad_request
        end

        def unsupported
          response.set_header("Allow", "POST")
          head :method_not_allowed
        end

        private

        def validate_transport!
          origin = request.headers["Origin"]
          if origin.present? && origin != request.base_url
            head :forbidden
            return
          end
          version = request.headers["MCP-Protocol-Version"]
          if version.present? && Management::Mcp::VERSIONS.exclude?(version)
            head :bad_request
            return
          end
          return unless request.post?

          unless request.media_type == "application/json"
            head :unsupported_media_type
            return
          end
          accept = request.headers["Accept"].to_s
          head :not_acceptable unless accept.include?("application/json") && accept.include?("text/event-stream")
        end
      end
    end
  end
end

module Postnhost
  module Management
    class Mcp
      VERSIONS = %w[2025-11-25 2025-06-18 2025-03-26].freeze

      def initialize(user:, script_name: "")
        @user = user
        @script_name = script_name
      end

      def call(message)
        return error(nil, -32_600, "Invalid Request") unless message.is_a?(Hash)

        id = message["id"]
        return error(nil, -32_600, "Invalid Request") unless message["jsonrpc"] == "2.0" && message["method"].is_a?(String) && (!message.key?("id") || id.is_a?(String) || id.is_a?(Integer))
        return nil unless message.key?("id")

        params = message.fetch("params", {})
        return error(id, -32_602, "params must be an object") unless params.is_a?(Hash)

        result = case message["method"]
                 when "initialize"
                   { protocolVersion: VERSIONS.include?(params["protocolVersion"]) ? params["protocolVersion"] : VERSIONS.first,
                     capabilities: { tools: { listChanged: false } }, serverInfo: { name: "PostnHost", version: Postnhost::VERSION },
                     instructions: "Manage CMS drafts, translations and settings. Publishing is explicit. Generate translations from published sources. Files use base64 and follow the same upload limits as the CMS." }
                 when "ping" then {}
                 when "tools/list" then { tools: Catalog.tools }
                 when "tools/call" then call_tool(params)
                 else return error(id, -32_601, "Method not found")
                 end
        { jsonrpc: "2.0", id:, result: }
      rescue ArgumentError => e
        error(id, -32_602, e.message)
      end

      private

      def call_tool(params)
        name = params.fetch("name", "")
        Catalog.fetch(name)
        arguments = params.fetch("arguments", {})
        raise ArgumentError, "arguments must be an object" unless arguments.is_a?(Hash)

        result = Command.call(name:, arguments:, user: @user, script_name: @script_name)
        data = { data: result.value, errors: result.errors, status: Rack::Utils.status_code(result.status) }
        { content: [{ type: "text", text: data.to_json }], structuredContent: data, isError: !result.success? || data[:status] >= 400 }
      end

      def error(id, code, message)
        { jsonrpc: "2.0", id:, error: { code:, message: } }
      end
    end
  end
end

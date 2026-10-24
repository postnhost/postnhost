module Postnhost
  module Api
    module V1
      module Openapi
        def self.document(server:)
          { openapi: "3.1.0", info: { title: "PostnHost CMS management API", version: "1" }, servers: [{ url: server }],
            security: [{ bearerAuth: [] }], components: { securitySchemes: { bearerAuth: { type: "http", scheme: "bearer" } } },
            paths: Management::Catalog.tools.to_h { |tool| ["/commands/#{tool[:name]}", { post: operation(tool) }] } }
        end

        def self.operation(tool)
          { operationId: tool[:name], summary: tool[:description],
            requestBody: { required: true, content: { "application/json" => { schema: { type: "object", required: ["arguments"], properties: { arguments: tool[:inputSchema] } } } } },
            responses: {
              "200" => { description: "Command completed. JSON contains data and errors." },
              "202" => { description: "Translation queued. Poll the variant's generating field." },
              "400" => { description: "Invalid arguments." }, "401" => { description: "Invalid bearer token." },
              "404" => { description: "Record not found in the requested scope." },
              "409" => { description: "Conflicting data or protected action." },
              "422" => { description: "Validation or publication failure. Bulk results contain per-record failures." },
              "503" => { description: "Translation queue unavailable. Data identifies queued work and failed_language_ids to retry." }
            } }
        end
      end
    end
  end
end

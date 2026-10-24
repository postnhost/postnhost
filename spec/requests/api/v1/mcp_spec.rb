require "rails_helper"

RSpec.describe "CMS MCP endpoint", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:secret) { Postnhost::ApiToken.issue!(user:, name: "MCP").last }
  let(:headers) { { "Authorization" => "Bearer #{secret}", "Accept" => "application/json, text/event-stream", "Content-Type" => "application/json" } }

  before { host! "example.com" }

  def rpc(method, params = {}, id: 1)
    message = { jsonrpc: "2.0", method:, params: }
    message[:id] = id unless id.nil?
    post postnhost.api_v1_mcp_path, params: message.to_json, headers: headers
    response.parsed_body if response.body.present?
  end

  it "negotiates capabilities and serves the same API command schemas" do
    data = rpc("initialize", { protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "Spec", version: "1" } })
    expect(data.dig("result", "protocolVersion")).to eq("2025-11-25")
    expect(data.dig("result", "capabilities", "tools")).to be_present
    rpc("notifications/initialized", id: nil)
    expect(response).to have_http_status(:accepted)
    tools = rpc("tools/list").dig("result", "tools")
    get postnhost.api_v1_commands_path, headers: headers
    expect(response).to have_http_status(:ok)
    expect(tools).to eq(response.parsed_body.fetch("commands"))
  end

  it "executes commands and returns structured and text results" do
    data = rpc("tools/call", { name: "articles_create", arguments: { attributes: { title: "Agent draft" } } })
    expect(data.dig("result", "isError")).to be false
    expect(data.dig("result", "structuredContent", "data", "title")).to eq("Agent draft")
    expect(Postnhost::Article.last.user).to eq(user)
    id = data.dig("result", "structuredContent", "data", "id")
    data = rpc("tools/call", { name: "articles_publish", arguments: { id: } })
    expect(data.dig("result", "isError")).to be true
    expect(data.dig("result", "content", 0, "type")).to eq("text")
  end

  it "returns compact list summaries while get preserves full content" do
    article = create(:article, :published, user:, language: default_language, content: "<p>#{'x' * 100_000}</p>")
    data = rpc("tools/call", { name: "articles_list", arguments: { mine: true } })
    summary = data.dig("result", "structuredContent", "data", "records", 0)
    expect(summary).to include("id" => article.id, "published" => true)
    expect(summary).not_to have_key("content")
    expect(response.body.bytesize).to be < 3000
    data = rpc("tools/call", { name: "articles_get", arguments: { id: article.id } })
    expect(data.dig("result", "structuredContent", "data", "content")).to eq(article.content)
  end

  it "returns protocol errors for unknown tools, methods and malformed messages" do
    expect(rpc("missing").dig("error", "code")).to eq(-32_601)
    expect(rpc("tools/call", { name: "missing" }).dig("error", "code")).to eq(-32_602)
    post postnhost.api_v1_mcp_path, params: "[{}]", headers: headers
    expect(response).to have_http_status(:bad_request)
    post postnhost.api_v1_mcp_path, params: "{", headers: headers
    expect(response.parsed_body.dig("error", "code")).to eq(-32_700)
  end

  it "rejects foreign origins, unsupported versions and missing transport headers" do
    headers["Origin"] = "https://evil.example"
    rpc("ping")
    expect(response).to have_http_status(:forbidden)
    headers.delete("Origin")
    headers["MCP-Protocol-Version"] = "1999-01-01"
    rpc("ping")
    expect(response).to have_http_status(:bad_request)
    headers.delete("MCP-Protocol-Version")
    headers["Accept"] = "application/json"
    rpc("ping")
    expect(response).to have_http_status(:not_acceptable)
  end

  it "does not offer a server notification stream or stateful sessions" do
    get postnhost.api_v1_mcp_path, headers: headers
    expect(response).to have_http_status(:method_not_allowed)
    delete postnhost.api_v1_mcp_path, headers: headers
    expect(response).to have_http_status(:method_not_allowed)
  end
end

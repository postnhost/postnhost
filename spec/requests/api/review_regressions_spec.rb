require "rails_helper"

RSpec.describe "CMS management review regressions", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:secret) { Postnhost::ApiToken.issue!(user:, name: "Regression checks").last }
  let(:headers) { { "Authorization" => "Bearer #{secret}" } }
  let(:file) do
    { filename: "branding.webp", content_type: "image/webp",
      base64: Base64.strict_encode64(File.binread(Postnhost::Engine.root.join("spec/fixtures/files/cover_image.webp"))) }
  end

  before { host! "example.com" }

  def command(name, arguments = {}, mount: "")
    post "/api/v1/commands/#{name}", params: { arguments: }, headers: headers.merge("SCRIPT_NAME" => mount), as: :json
    response.parsed_body
  end

  def rpc(name, arguments = {}, mount: "")
    message = { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name:, arguments: } }
    post "/api/v1/mcp", params: message.to_json,
                        headers: headers.merge("SCRIPT_NAME" => mount, "Accept" => "application/json, text/event-stream", "Content-Type" => "application/json")
    response.parsed_body.fetch("result")
  end

  it "returns a retryable API queue failure and allows retry after recovery" do
    article = create(:article, :published, user:, language: default_language)
    language = create(:language, :spanish)
    allow(Postnhost::Translation::ArticleVariantJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError)
    data = command("articles_translate", { id: article.id, language_ids: [language.id] })
    expect(response).to have_http_status(:service_unavailable)
    expect(data.dig("data", "failed_language_ids")).to eq([language.id])
    expect(data.fetch("errors")).not_to be_empty
    expect(article.article_variants).to be_empty

    allow(Postnhost::Translation::ArticleVariantJob).to receive(:perform_later).and_call_original
    command("articles_translate", { id: article.id, language_ids: [language.id] })
    expect(response).to have_http_status(:accepted)
    expect(article.article_variants.reload.sole).to be_generating
  end

  it "shows an error in the UI without leaving a stuck translation" do
    sign_in user
    article = create(:article, :published, user:, language: default_language)
    language = create(:language, :spanish)
    allow(Postnhost::Translation::ArticleVariantJob).to receive(:perform_later).and_return(false)
    post postnhost.article_translations_path(article), params: { language_ids: [language.id] }
    expect(response).to redirect_to(postnhost.article_variants_path(article))
    expect(flash[:alert]).to include("Retry the failed languages")
    expect(article.article_variants).to be_empty
  end

  it "reports queue failures as MCP execution errors with retry languages" do
    article = create(:article, :published, user:, language: default_language)
    language = create(:language, :spanish)
    allow(Postnhost::Translation::ArticleVariantJob).to receive(:perform_later).and_return(false)
    result = rpc("articles_translate", { id: article.id, language_ids: [language.id] })
    expect(result.fetch("isError")).to be true
    expect(result.dig("structuredContent", "status")).to eq(503)
    expect(result.dig("structuredContent", "data", "failed_language_ids")).to eq([language.id])
  end

  { "logo" => "site_logo", "og_image" => "og_image" }.each do |suffix, field|
    it "removes the #{suffix} through API and MCP, including repeated removal" do
      command("settings_upload_#{suffix}", { file: })
      expect(response).to have_http_status(:ok)
      expect(Postnhost::Setting.current.public_send(field).url).to be_present
      data = command("settings_remove_#{suffix}")
      expect(response).to have_http_status(:ok)
      expect(data.dig("data", field)).to be_nil
      expect(data.dig("data", "#{field}_url")).to be_nil
      expect(Postnhost::Setting.current.public_send(field).url).to be_nil

      command("settings_upload_#{suffix}", { file: })
      result = rpc("settings_remove_#{suffix}")
      expect(result.fetch("isError")).to be false
      expect(Postnhost::Setting.current.public_send(field).url).to be_nil
      command("settings_remove_#{suffix}")
      expect(response).to have_http_status(:ok)
      tool = Postnhost::Management::Catalog.fetch("settings_remove_#{suffix}")
      expect(tool[:annotations]).to include(destructiveHint: true, idempotentHint: true)
    end
  end

  it "keeps nested mount prefixes in API template and article preview links" do
    %w[default swiss-editorial workspace-journal].each do |template|
      data = command("template_preview", { name: template }, mount: "/cms/blog")
      expect(response).to have_http_status(:ok)
      expect(data.dig("data", "html")).to include('href="/cms/blog/articles?preview_template=')
      expect(data.dig("data", "html")).not_to include('href="/articles?preview_template=')
    end
    article = create(:article, user:, language: default_language)
    data = command("articles_preview", { id: article.id }, mount: "/cms/blog")
    expect(response).to have_http_status(:ok)
    expect(data.dig("data", "html")).to include('href="/cms/blog/articles"')
  end

  it "keeps mount prefixes in MCP previews" do
    result = rpc("template_preview", { name: "default" }, mount: "/blog")
    expect(result.fetch("isError")).to be false
    expect(result.dig("structuredContent", "data", "html")).to include('href="/blog/articles?preview_template=default"')
  end
end

require "rails_helper"

RSpec.describe "CMS command API", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:issued) { Postnhost::ApiToken.issue!(user:, name: "Integration") }
  let(:headers) { { "Authorization" => "Bearer #{issued.last}" } }

  before { host! "example.com" }

  def command(name, arguments = {})
    post postnhost.api_v1_command_path(command: name), params: { arguments: }, headers:, as: :json
    response.parsed_body
  end

  it "requires bearer authentication even with a CMS session" do
    sign_in user
    get postnhost.api_v1_commands_path
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["Cache-Control"]).to eq("no-store")
  end

  it "publishes a discoverable command catalog" do
    get postnhost.api_v1_commands_path, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("commands").pluck("name")).to include("articles_publish", "settings_replace_navigation", "users_upload_avatar")
  end

  it "serves OpenAPI using the shared command schemas" do
    get postnhost.api_v1_openapi_path, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("openapi")).to eq("3.1.0")
    expect(response.parsed_body.dig("paths", "/commands/articles_create", "post", "operationId")).to eq("articles_create")
  end

  it "manages only the caller's integration tokens" do
    token = command("api_tokens_create", attributes: { name: "Second agent" }).fetch("data")
    expect(Postnhost::ApiToken.authenticate(token.fetch("secret")).user).to eq(user)
    expect(token.fetch("token")).not_to have_key("token_digest")
    other, = Postnhost::ApiToken.issue!(user: create(:user), name: "Other")
    command("api_tokens_get", id: other.id)
    expect(response).to have_http_status(:not_found)
    command("api_tokens_delete", id: token.dig("token", "id"))
    expect(Postnhost::ApiToken.authenticate(token.fetch("secret"))).to be_nil
  end

  it "rejects non-object arguments with a JSON error" do
    post postnhost.api_v1_command_path(command: "articles_list"), params: { arguments: [] }, headers:, as: :json
    expect(response).to have_http_status(:bad_request)
  end

  it "renders a template preview without changing the active template" do
    command("template_preview", name: "swiss-editorial")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "html")).to include("<!DOCTYPE html>")
    expect(Postnhost::Template.active_name).to eq("default")
  end

  it "rejects revoked credentials" do
    issued.first.revoke!
    get postnhost.api_v1_commands_path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "validates input before creating records" do
    expect { command("articles_create", attributes: { user_id: user.id, title: "Attempt" }) }.not_to change(Postnhost::Article, :count)
    expect(response).to have_http_status(:bad_request)
    command("articles_list", limit: 101)
    expect(response).to have_http_status(:bad_request)
    command("articles_get", id: "1")
    expect(response).to have_http_status(:bad_request)
    command("unknown")
    expect(response).to have_http_status(:bad_request)
  end

  it "creates drafts, preserves snapshots on edits, restores history and unpublishes" do
    data = command("articles_create", attributes: { title: "Original", content: "<p>Original body</p>" }).fetch("data")
    id = data.fetch("id")
    expect(data.fetch("published")).to be false
    command("articles_publish", id:)
    expect(response).to have_http_status(:ok)
    expect(Postnhost::Article.find(id).article_snapshot.title).to eq("Original")
    command("articles_update", id:, attributes: { title: "Changed" })
    expect(Postnhost::Article.find(id).article_snapshot.title).to eq("Original")
    versions = command("articles_versions", id:).fetch("data")
    version_id = versions.first.fetch("id")
    preview = command("articles_version_preview", id:, version_id:).fetch("data")
    expect(preview.fetch("title")).to eq("Original")
    command("articles_restore", id:, version_id:)
    expect(Postnhost::Article.find(id).title).to eq("Original")
    command("articles_preview", id:)
    expect(response.parsed_body.dig("data", "html")).to include("<p>Original body</p>")
    command("articles_unpublish", id:)
    expect(Postnhost::Article.find(id)).not_to be_published
    command("articles_delete", id:)
    expect(response.parsed_body.dig("data", "deleted")).to be true
  end

  it "returns publication errors without creating a public snapshot" do
    article = create(:article, title: nil, content: nil)
    command("articles_publish", id: article.id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).not_to be_empty
    expect(article.reload).not_to be_published
  end

  it "schedules and cancels article publication through the existing workflow" do
    article = create(:article)
    expect { command("articles_update", id: article.id, attributes: { scheduled_at: 1.hour.from_now.iso8601 }) }.to have_enqueued_job(Postnhost::ScheduledArticleJob)
    expect(article.reload.scheduled_job_id).to be_present
    command("articles_update", id: article.id, attributes: { scheduled_at: nil })
    expect(article.reload.scheduled_at).to be_nil
    expect(article.scheduled_job_id).to be_nil
  end

  it "manages article relationships and filters lists" do
    category = create(:category)
    article = create(:article, user:)
    command("articles_update", id: article.id, attributes: { author_ids: [user.id], category_ids: [category.id], top_pick: true })
    expect(response.parsed_body.dig("data", "category_ids")).to eq([category.id])
    command("articles_list", mine: true, status: "draft", limit: 1, page: 1)
    expect(response.parsed_body.dig("data", "total")).to eq(1)
    expect(response.parsed_body.dig("data", "records", 0, "id")).to eq(article.id)
  end

  it "scopes variants to their parent and prevents edits during generation" do
    language = create(:language, :spanish)
    article = create(:article)
    other_article = create(:article)
    data = command("article_variants_create", parent_id: article.id, attributes: { language_id: language.id }).fetch("data")
    expect(data.fetch("title")).to eq(article.title)
    id = data.fetch("id")
    command("article_variants_get", parent_id: other_article.id, id:)
    expect(response).to have_http_status(:not_found)
    Postnhost::ArticleVariant.find(id).update!(generating: true)
    command("article_variants_update", parent_id: article.id, id:, attributes: { title: "Wrong" })
    expect(response).to have_http_status(:bad_request)
    command("article_variants_bulk_delete", parent_id: article.id, ids: [id])
    expect(response).to have_http_status(:unprocessable_content)
    expect(Postnhost::ArticleVariant.exists?(id)).to be true
  end

  it "supports bulk publication and reports failures per variant" do
    article = create(:article, :published)
    language = create(:language, :spanish)
    data = command("article_variants_create", parent_id: article.id, attributes: { language_id: language.id }).fetch("data")
    id = data.fetch("id")
    command("article_variants_bulk_publish", parent_id: article.id, ids: [id, 999_999])
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("data", "failures", "999999")).to be_present
    expect(Postnhost::ArticleVariant.find(id)).to be_published
    command("article_variants_bulk_unpublish", parent_id: article.id, ids: [id])
    expect(Postnhost::ArticleVariant.find(id)).not_to be_published
    command("article_variants_bulk_delete", parent_id: article.id, ids: [id])
    expect(Postnhost::ArticleVariant.exists?(id)).to be false
  end

  it "creates placeholders before enqueueing translations and exposes their status" do
    article = create(:article, :published)
    language = create(:language, :spanish)
    expect { command("articles_translate", id: article.id, language_ids: [language.id]) }.to have_enqueued_job(Postnhost::Translation::ArticleVariantJob).with(article.id, language.id)
    expect(response).to have_http_status(:accepted)
    expect(response.parsed_body.dig("data", "variants", 0, "generating")).to be true
    command("article_variants_list", parent_id: article.id)
    expect(response.parsed_body.dig("data", "records", 0, "generating")).to be true
  end

  it "rejects invalid translation batches atomically" do
    article = create(:article, :published)
    language = create(:language, :spanish)
    expect { command("articles_translate", id: article.id, language_ids: [language.id, 999_999]) }.not_to change(Postnhost::ArticleVariant, :count)
    expect(response).to have_http_status(:not_found)
    command("articles_translate", id: article.id, language_ids: [default_language.id])
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "manages pages and their publication variants" do
    data = command("pages_create", attributes: { title: "About", content: "<p>About</p>" }).fetch("data")
    id = data.fetch("id")
    command("pages_publish", id:)
    expect(Postnhost::Page.find(id)).to be_published
    language = create(:language, :spanish)
    variant = command("page_variants_create", parent_id: id, attributes: { language_id: language.id }).fetch("data")
    command("page_variants_bulk_publish", parent_id: id, ids: [variant.fetch("id")])
    expect(response).to have_http_status(:ok)
    command("page_variants_unpublish", parent_id: id, id: variant.fetch("id"))
    command("pages_unpublish", id:)
    expect(Postnhost::Page.find(id)).not_to be_published
  end

  it "manages categories, category translations and languages" do
    language = command("languages_create", attributes: { name: "Spanish", html_lang: "es", default: false }).fetch("data")
    category = command("categories_create", attributes: { name: "Guides", slug: "guides" }).fetch("data")
    variant = command("category_variants_create", parent_id: category.fetch("id"), attributes: { language_id: language.fetch("id"), name: "Guías" }).fetch("data")
    command("category_variants_update", parent_id: category.fetch("id"), id: variant.fetch("id"), attributes: { meta_description: "Descripción" })
    expect(response).to have_http_status(:ok)
    command("category_variants_delete", parent_id: category.fetch("id"), id: variant.fetch("id"))
    command("categories_delete", id: category.fetch("id"))
    command("languages_delete", id: language.fetch("id"))
    expect(response).to have_http_status(:ok)
  end

  it "manages authors without exposing password digests and prevents self deletion" do
    author = command("users_create", attributes: { name: "Writer", email: "writer@example.com", password: "password" }).fetch("data")
    expect(author).not_to have_key("password_digest")
    command("users_update", id: author.fetch("id"), attributes: { schema_profile: { same_as: ["https://example.com"] }, schema_locale_overrides: { en: { bio: "Bio" } } })
    expect(response).to have_http_status(:ok)
    article = create(:article, user: Postnhost::User.find(author.fetch("id")))
    command("users_delete", id: author.fetch("id"))
    expect(response).to have_http_status(:ok)
    expect(article.reload.user_id).to be_nil
    command("users_delete", id: user.id)
    expect(response).to have_http_status(:conflict)
  end

  it "manages settings, localized copy, schema, templates and scripts" do
    command("settings_update", attributes: { site_url: "https://blog.example.com", timezone: "UTC", search_enabled: false, schema_settings: { organization_type: "Organization" } })
    expect(response).to have_http_status(:ok)
    expect(Postnhost::Setting.current.search_enabled).to be false
    command("settings_update_translations", locale: "en", translations: { "postnhost.public.site.blog_meta_description" => "New copy" })
    expect(response).to have_http_status(:ok)
    command("settings_get_translations", locale: "en")
    expect(response.parsed_body.dig("data", "postnhost.public.site.blog_meta_description")).to eq("New copy")
    command("settings_get_translations", locale: "xx")
    expect(response).to have_http_status(:bad_request)
    command("template_update", attributes: { name: "swiss-editorial" })
    expect(Postnhost::Template.active_name).to eq("swiss-editorial")
    command("template_update", attributes: { name: "unknown" })
    expect(response).to have_http_status(:unprocessable_content)
    expect(Postnhost::Template.active_name).to eq("swiss-editorial")
    command("site_scripts_create", attributes: { placement: "unknown", script: "<script>example()</script>" })
    expect(response).to have_http_status(:unprocessable_content)
    script = command("site_scripts_create", attributes: { placement: "head", script: "<script>example()</script>" }).fetch("data")
    command("site_scripts_delete", id: script.fetch("id"))
    expect(response).to have_http_status(:ok)
  end

  it "replaces navigation transactionally and preserves it on invalid input" do
    tree = { header: [{ kind: "link", target_kind: "external", url: "https://example.com", label: "Home", children: [] }], footer: [] }
    command("settings_replace_navigation", locale: "en", tree:)
    expect(response).to have_http_status(:ok)
    command("settings_get_navigation", locale: "en")
    expect(response.parsed_body.dig("data", "tree", "header", 0, "label")).to eq("Home")
    command("settings_replace_navigation", locale: "en", tree: { header: [{ kind: "link" }], footer: [] })
    expect(response).to have_http_status(:unprocessable_content)
    expect(Postnhost::Setting.current.current_navigation.navigation_items.count).to eq(1)

    [
      { header: [{ kind: "dropdown", children: "invalid" }], footer: [] },
      { header: Array.new(101, tree[:header].first), footer: [] },
      { header: [{ kind: "dropdown", children: [{ kind: "link", children: [{ kind: "link", children: [] }] }] }], footer: [] }
    ].each do |invalid_tree|
      command("settings_replace_navigation", locale: "en", tree: invalid_tree)
      expect(response).to have_http_status(:bad_request)
    end
    command("settings_get_navigation", locale: "en")
    expect(response.parsed_body.dig("data", "tree", "header", 0, "label")).to eq("Home")
  end

  it "uploads and removes cover images while retaining published files" do
    article = create(:article)
    file = { filename: "cover.webp", content_type: "image/webp", base64: Base64.strict_encode64(File.binread(Postnhost::Engine.root.join("spec/fixtures/files/cover_image.webp"))) }
    command("articles_upload_cover", id: article.id, file:)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "url")).to be_present
    command("articles_publish", id: article.id)
    identifier = article.reload.cover_image.identifier
    command("articles_remove_cover", id: article.id)
    expect(article.reload.cover_image.identifier).to be_nil
    expect(article.article_snapshot.cover_image.identifier).to eq(identifier)
    command("articles_upload_image", id: article.id, file:)
    expect(response).to have_http_status(:ok)
  end

  it "uses the shared inline image size limit instead of a separate API limit" do
    article = create(:article)
    image = File.binread(Postnhost::Engine.root.join("spec/fixtures/files/cover_image.webp"))
    file = { filename: "image.webp", content_type: "image/webp", base64: Base64.strict_encode64(image.ljust(11.megabytes, "\0")) }
    command("articles_upload_image", id: article.id, file:)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "url")).to be_present

    file[:base64] = Base64.strict_encode64(image.ljust(Postnhost::InlineImageUploadable::IMAGE_MAX_SIZE + 1, "\0"))
    command("articles_upload_image", id: article.id, file:)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("errors")).to include("File too large")
  end

  it "rejects invalid uploads" do
    article = create(:article)
    command("articles_upload_cover", id: article.id, file: { filename: "../a.png", content_type: "image/webp", base64: "bad" })
    expect(response).to have_http_status(:bad_request)
  end
end

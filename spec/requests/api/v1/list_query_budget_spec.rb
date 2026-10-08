require "rails_helper"

RSpec.describe "CMS API list query budgets", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:secret) { Postnhost::ApiToken.issue!(user:, name: "Query budget").last }
  let(:headers) { { "Authorization" => "Bearer #{secret}" } }

  before do
    host! "example.com"
    headers
    Postnhost::Setting.current
  end

  def list(resource, arguments = {})
    post postnhost.api_v1_command_path(command: "#{resource}_list"), params: { arguments: }, headers:, as: :json
  end

  %i[draft published].each do |status|
    it "keeps #{status} article queries bounded as the page grows to 25 records" do
      traits = status == :published ? [:published] : []
      create(:article, *traits, user:, language: default_language)
      single_queries = capture_sql_queries { list("articles", status: status.to_s, mine: true, limit: 25) }
      create_list(:article, 24, *traits, user:, language: default_language)
      queries = capture_sql_queries { list("articles", status: status.to_s, mine: true, limit: 25) }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "records").size).to eq(25)
      expect(queries.size).to be <= 6, queries.join("\n")
      expect(queries.size).to be <= single_queries.size, queries.join("\n")
      expect(queries.grep(/postnhost_(?:article_authors|article_categories|article_suggestions|versions)/)).to be_empty
      expect(queries.grep(/SELECT.*"content"/)).to be_empty
      expect(response.parsed_body.dig("data", "records").pluck("published")).to all(eq(status == :published))
    end
  end

  it "lists published pages without loading their bodies or comparing draft content" do
    create_list(:page, 25, :published, user:, language: default_language)
    queries = capture_sql_queries { list("pages", limit: 25) }

    expect(response).to have_http_status(:ok)
    expect(queries.size).to be <= 6, queries.join("\n")
    expect(queries.grep(/SELECT.*"content"/)).to be_empty
    expect(response.parsed_body.dig("data", "records").pluck("published")).to all(be(true))
  end

  %w[article page].each do |kind|
    it "lists 15 #{kind} translations with a constant query budget" do
      parent = create(kind.to_sym, :published, user:, language: default_language)
      15.times do |index|
        language = create(:language, name: "Locale #{index}", html_lang: "perf-#{index}", default: false)
        create(:"#{kind}_variant", :published, kind.to_sym => parent, language:)
      end
      queries = capture_sql_queries { list("#{kind}_variants", parent_id: parent.id, limit: 25) }

      expect(response).to have_http_status(:ok)
      expect(queries.size).to be <= 7, queries.join("\n")
      expect(response.parsed_body.dig("data", "records").size).to eq(15)
      expect(response.parsed_body.dig("data", "records").pluck("published")).to all(be(true))
      expect(queries.grep(/SELECT.*"content"/)).to be_empty
    end
  end

  it "keeps summaries small while get returns content, associations and draft changes" do
    body = "<p>#{'x' * 100_000}</p>"
    category = create(:category)
    article = create(:article, :published, user:, language: default_language, content: body)
    article.update!(title: "Updated draft", category_ids: [category.id])
    list("articles", mine: true)

    expect(response.body.bytesize).to be < 2000
    summary = response.parsed_body.dig("data", "records", 0)
    expect(summary).to include("id" => article.id, "title" => "Updated draft", "published" => true)
    expect(summary.keys).not_to include("content", "author_ids", "category_ids", "unpublished_changes", "management_snapshot_id")

    post postnhost.api_v1_command_path(command: "articles_get"), params: { arguments: { id: article.id } }, headers:, as: :json
    expect(response.parsed_body.fetch("data")).to include("content" => body, "category_ids" => [category.id], "author_ids" => [user.id], "unpublished_changes" => true)
  end

  it "reflects unpublishing immediately without caching CMS data" do
    article = create(:article, :published, user:, language: default_language)
    list("articles", mine: true)
    expect(response.parsed_body.dig("data", "records", 0, "published")).to be true
    Postnhost::Publishing::Articles::Unpublish.call(article:)
    list("articles", mine: true)
    expect(response.parsed_body.dig("data", "records", 0, "published")).to be false
  end

  it "reads version metadata without fetching saved article bodies" do
    article = create(:article, :published, user:, language: default_language, content: "<p>#{'x' * 100_000}</p>")
    queries = capture_sql_queries do
      post postnhost.api_v1_command_path(command: "articles_versions"), params: { arguments: { id: article.id } }, headers:, as: :json
    end

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").first).to include("item_id" => article.id, "item_type" => "Postnhost::Article")
    expect(response.body.bytesize).to be < 1000
    record_queries = queries.grep(/FROM "postnhost_(?:articles|versions)"/)
    expect(record_queries.size).to be <= 2
    expect(record_queries.join).not_to include('"content"', '"object"', ".*")
  end

  it "keeps token revocation visible without exposing digests" do
    token, = Postnhost::ApiToken.issue!(user:, name: "Revoked token")
    token.revoke!
    list("api_tokens")
    row = response.parsed_body.dig("data", "records").find { |record| record["id"] == token.id }
    expect(row.fetch("revoked_at")).to be_present
    expect(row).not_to have_key("token_digest")
  end
end

require "rails_helper"

RSpec.describe "Public publication query budgets", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }
  let(:user) { create(:user) }

  before do
    Postnhost::Setting.current
    Postnhost::Template.current
  end

  it "renders 15 default-language cards within the query budget" do
    create_list(:article, 15, :published, language: default_language, user:)

    queries = capture_sql_queries { get "/" }

    expect(response).to have_http_status(:ok)
    expect(queries.size).to be <= 20, queries.join("\n")
    expect(queries.grep(/postnhost_versions/)).to be_empty
  end

  it "adds no more than two queries when the page grows from one card to 15" do
    create(:article, :published, language: default_language, user:)
    one_card_queries = capture_sql_queries { get "/" }

    create_list(:article, 14, :published, language: default_language, user:)
    fifteen_card_queries = capture_sql_queries { get "/" }

    expect(fifteen_card_queries.size - one_card_queries.size).to be <= 2, fifteen_card_queries.join("\n")
  end

  it "renders 15 localized cards within the query budget" do
    articles = create_list(:article, 15, :published, language: default_language, user:)
    articles.each do |article|
      create(:article_variant, :published, article:, language: spanish)
    end

    queries = capture_sql_queries { get "/#{spanish.html_lang}" }

    expect(response).to have_http_status(:ok)
    expect(queries.size).to be <= 22, queries.join("\n")
    expect(queries.grep(/postnhost_versions/)).to be_empty
  end

  it "renders an article show page within the query budget" do
    article = create(:article, :published, language: default_language, user:)

    queries = capture_sql_queries { get "/#{article.slug}" }
    route_queries = queries.grep(/FROM "postnhost_article_snapshots".*"slug"/)
    category_route_queries = queries.grep(/FROM "postnhost_categories".*"slug"/)

    expect(response).to have_http_status(:ok)
    expect(queries.size).to be <= 17, queries.join("\n")
    expect(route_queries.size).to eq(1), route_queries.join("\n")
    expect(category_route_queries.size).to eq(1), category_route_queries.join("\n")
    expect(queries.grep(/postnhost_versions/)).to be_empty
  end

  it "reuses a category resolved by routing" do
    category = create(:category)
    article = create(:article, language: default_language, user:)
    create(:article_category, article:, category:)
    Postnhost::Publishing::Articles::Publish.call(article:)

    queries = capture_sql_queries { get "/#{category.slug}" }
    route_queries = queries.grep(/FROM "postnhost_categories".*"slug"/)

    expect(response).to have_http_status(:ok)
    expect(route_queries.size).to eq(1), route_queries.join("\n")
  end

  it "reuses a page resolved by routing" do
    page = create(:page, :published, language: default_language, user:)

    queries = capture_sql_queries { get "/#{page.slug}" }
    route_queries = queries.grep(/FROM "postnhost_page_snapshots".*"slug" =/)

    expect(response).to have_http_status(:ok)
    expect(route_queries.size).to eq(1), route_queries.join("\n")
  end

  it "loads request-wide site records once" do
    user
    queries = capture_sql_queries { get "/" }

    expect(response).to have_http_status(:ok)
    expect(queries.grep(/FROM "postnhost_settings"/).size).to eq(1)
    expect(queries.grep(/FROM "postnhost_templates"/).size).to eq(1)
    expect(queries.grep(/FROM "postnhost_public_site_revisions"/).size).to eq(1)
    expect(queries.grep(/FROM "postnhost_languages".*"default"/).size).to eq(1)
  end

  it "loads every script placement in one query" do
    article = create(:article, :published, language: default_language, user:)
    setting = Postnhost::Setting.current

    Postnhost::SiteScript::PLACEMENTS.each do |placement|
      5.times do |index|
        setting.site_scripts.create!(placement:, script: "<meta name=\"#{placement}-#{index}\">")
      end
    end

    queries = capture_sql_queries { get "/#{article.slug}" }
    site_script_queries = queries.grep(/FROM "postnhost_site_scripts"/)

    expect(response).to have_http_status(:ok)
    expect(site_script_queries.size).to eq(1), site_script_queries.join("\n")
  end

  it "returns a cheap 304 for an unchanged index" do
    create(:article, :published, language: default_language, user:)
    get "/"

    queries = capture_sql_queries do
      get "/", headers: { "HTTP_IF_NONE_MATCH" => response.headers.fetch("ETag") }
    end

    expect(response).to have_http_status(:not_modified)
    expect(queries.size).to be <= 5, queries.join("\n")
    expect(queries.grep(/postnhost_versions/)).to be_empty
  end

  it "returns a cheap 304 for an unchanged article" do
    article = create(:article, :published, language: default_language, user:)
    get "/#{article.slug}"

    queries = capture_sql_queries do
      get "/#{article.slug}", headers: { "HTTP_IF_NONE_MATCH" => response.headers.fetch("ETag") }
    end

    expect(response).to have_http_status(:not_modified)
    expect(queries.size).to be <= 7, queries.join("\n")
    expect(queries.grep(/postnhost_versions/)).to be_empty
  end

  context "with fragment caching enabled" do
    let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }
    let(:original_caching_config) do
      {
        perform_caching: Postnhost::PublicController.perform_caching,
        cache_store: Postnhost::PublicController.cache_store,
        collection_cache: ActionView::PartialRenderer.collection_cache
      }
    end

    before do
      original_caching_config
      Postnhost::PublicController.perform_caching = true
      Postnhost::PublicController.cache_store = cache_store
      ActionView::PartialRenderer.collection_cache = cache_store
      allow(Rails).to receive(:cache).and_return(cache_store)
    end

    after do
      cache_store.clear
      Postnhost::PublicController.perform_caching = original_caching_config.fetch(:perform_caching)
      Postnhost::PublicController.cache_store = original_caching_config.fetch(:cache_store)
      ActionView::PartialRenderer.collection_cache = original_caching_config.fetch(:collection_cache)
    end

    it "uses collection multi-fetches and lowers SQL on a warm index request" do
      create_list(:article, 15, :published, language: default_language, user:)
      allow(cache_store).to receive(:read_multi).and_call_original

      cold_queries = capture_sql_queries { get "/" }
      warm_queries = capture_sql_queries { get "/" }

      expect(response).to have_http_status(:ok)
      expect(cache_store).to have_received(:read_multi).at_least(:twice)
      expect(warm_queries.size).to be < cold_queries.size
    end

    it "does not query suggestion joins after the article fragment is warm" do
      article = create(:article, :published, language: default_language, user:)
      create_list(:article, 3, :published, language: default_language, user:)

      cold_queries = capture_sql_queries { get "/#{article.slug}" }
      warm_queries = capture_sql_queries { get "/#{article.slug}" }

      expect(response).to have_http_status(:ok)
      expect(cold_queries.grep(/postnhost_article_snapshot_suggestions/)).not_to be_empty
      expect(warm_queries.grep(/postnhost_article_snapshot_suggestions/)).to be_empty
      expect(warm_queries.size).to be < cold_queries.size
    end
  end
end

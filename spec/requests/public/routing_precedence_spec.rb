require "rails_helper"

RSpec.describe "Public routing precedence", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  before { host! "example.com" }

  it "keeps a visible category ahead of an article and page with the same slug" do
    category = create(:category, name: "Winning category")
    article = create(:article, language: default_language, user:, content: "Article loser")
    create(:article_category, article:, category:)
    Postnhost::Publishing::Articles::Publish.call(article:)
    page = create(:page, :published, language: default_language, user:, content: "Page loser")
    simulate_legacy_slug_collision(category:, article:, page:)

    get "/shared-slug"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("h1").text).to include("Winning category")
    expect(response.body).not_to include("Page loser")
  end

  it "keeps an article ahead of a page when the matching category has no visible publication" do
    category = create(:category, name: "Hidden category")
    article = create(:article, :published, language: default_language, user:, content: "Article winner")
    page = create(:page, :published, language: default_language, user:, content: "Page loser")
    simulate_legacy_slug_collision(category:, article:, page:)

    get "/shared-slug"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Article winner")
    expect(response.body).not_to include("Page loser")
  end

  it "uses a page when no visible category or article owns the slug" do
    create(:page, :published, language: default_language, user:, slug: "shared-slug", content: "Page winner")

    get "/shared-slug"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Page winner")
  end

  def simulate_legacy_slug_collision(category:, article:, page:)
    category.update_column(:slug, "shared-slug")
    Postnhost::Snapshot::Article.find_by!(article_id: article.id).update_column(:slug, "shared-slug")
    Postnhost::Snapshot::Page.find_by!(page_id: page.id).update_column(:slug, "shared-slug")
  end
end

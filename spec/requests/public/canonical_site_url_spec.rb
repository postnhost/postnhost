require "rails_helper"

RSpec.describe "Public canonical site URL", type: :request do
  let!(:default_language) { create(:language, :default) }

  around do |example|
    original_site_url = Postnhost.config.site_url
    Postnhost.configure { |config| config.site_url = nil }
    example.run
  ensure
    Postnhost.configure { |config| config.site_url = original_site_url }
  end

  before { host! "example.com" }

  it "uses the configured origin for canonical, social, and hreflang URLs" do
    Postnhost::Setting.current.update!(site_url: "https://canonical.example.com")
    article = create(:article, :published, language: default_language, slug: "canonical-article")

    get "/#{article.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      '<link rel="canonical" href="https://canonical.example.com/canonical-article"',
      '<meta property="og:url" content="https://canonical.example.com/canonical-article"',
      'hreflang="en" href="https://canonical.example.com/canonical-article"'
    )
  end

  it "uses the request origin when the canonical origin is unconfigured" do
    Postnhost::Setting.current.update_column(:site_url, nil)
    article = create(:article, :published, language: default_language, slug: "request-origin-article")

    get "/#{article.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      '<link rel="canonical" href="http://example.com/request-origin-article"',
      '<meta property="og:url" content="http://example.com/request-origin-article"'
    )
  end

  it "uses the initializer default when the dashboard origin is blank" do
    Postnhost::Setting.current.update_column(:site_url, nil)
    Postnhost.configure { |config| config.site_url = "https://initializer.example.com" }
    article = create(:article, :published, language: default_language, slug: "initializer-origin-article")

    get "/#{article.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      '<link rel="canonical" href="https://initializer.example.com/initializer-origin-article"',
      '<meta property="og:url" content="https://initializer.example.com/initializer-origin-article"'
    )
  end
end

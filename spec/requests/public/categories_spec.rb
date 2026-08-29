require "rails_helper"

RSpec.describe "Public::Categories", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish_language) { create(:language, :spanish) }
  let!(:category) { create(:category) }
  let!(:published_article) { create(:article, :published) }
  let!(:unpublished_article) { create(:article) }
  let!(:published_variant) { create(:article_variant, :published, article: published_article, language: spanish_language) }

  before do
    create(:article_category, article: published_article, category:)
    create(:article_category, article: unpublished_article, category:)
    Postnhost::Publishing::Articles::Publish.call(article: published_article)
  end

  describe "GET /:category_slug" do
    it "returns http success" do
      get "/#{category.slug}"
      expect(response).to have_http_status(:success)
    end

    it "returns 304 when the public site is unchanged" do
      get "/#{category.slug}"
      etag = response.headers.fetch("ETag")

      get "/#{category.slug}", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "shows published articles in the category" do
      get "/#{category.slug}"
      expect(response.body).to include(published_article.title)
    end

    it "only advertises locales with published category content" do
      german_language = create(:language, :german)

      get "/#{category.slug}"

      alternates = response.parsed_body.css('link[rel="alternate"][hreflang]')
      alternate_languages = alternates.pluck("hreflang")

      expect(alternate_languages).to contain_exactly(default_language.html_lang, spanish_language.html_lang, "x-default")
      expect(alternate_languages).not_to include(german_language.html_lang)
    end

    it "renders category pages with the workspace-journal template" do
      Postnhost::Template.current.update!(name: "workspace-journal")

      get "/#{category.slug}"

      document = response.parsed_body
      category_heading = document.at_css("aside h1")

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include(published_article.title)
      expect(category_heading["class"].to_s.split).not_to include("break-words")
    end

    it "returns 404 for a category without a visible publication" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      empty_category = create(:category, name: "Empty Sidebar Category", slug: "empty-sidebar-category")

      get "/#{empty_category.slug}"

      expect(response).to have_http_status(:not_found)
    end

    it "does not show unpublished articles" do
      get "/#{category.slug}"
      expect(response.body).not_to include(unpublished_article.title)
    end

    it "returns 404 for non-existent category" do
      get "/non-existent-category"
      expect(response).to have_http_status(:not_found)
    end

    it "redirects page=1 to canonical category URL" do
      get "/#{category.slug}?page=1"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/#{category.slug}")
    end

    it "redirects page=1 and preserves other query params" do
      get "/#{category.slug}?page=1&utm_source=search"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/#{category.slug}?utm_source=search")
    end

    it "omits description meta tags on paginated category pages" do
      create_list(:article, 20, :published, language: default_language).each do |article|
        create(:article_category, article:, category:)
        Postnhost::Publishing::Articles::Publish.call(article:)
      end

      get "/#{category.slug}?page=2"

      expect(response.body).not_to include('name="description"')
      expect(response.body).not_to include('property="og:description"')
      expect(response.body).not_to include('name="twitter:description"')
    end
  end

  describe "GET /:locale/:category_slug" do
    it "returns http success for localized category pages" do
      get "/#{spanish_language.html_lang}/#{category.slug}"

      expect(response).to have_http_status(:success)
    end

    it "uses the localized category as canonical when it has published localized content" do
      get "/#{spanish_language.html_lang}/#{category.slug}"

      canonical = response.parsed_body.at_css('link[rel="canonical"]')

      expect(URI.parse(canonical["href"]).path).to eq("/#{spanish_language.html_lang}/#{category.slug}")
    end

    it "renders a localized category without localized content as a default-language fallback" do
      german_language = create(:language, :german)

      get "/#{german_language.html_lang}/#{category.slug}"

      document = response.parsed_body
      canonical = document.at_css('link[rel="canonical"]')

      expect(response).to have_http_status(:success)
      expect(document.at_css("html")["lang"]).to eq(german_language.html_lang)
      expect(response.body).to include(category.name)
      expect(response.body).not_to include(published_article.title)
      expect(URI.parse(canonical["href"]).path).to eq("/#{category.slug}")
      expect(document.css('link[rel="alternate"][hreflang]')).to be_empty
    end

    it "returns success for localized category pages when request has a mount script_name" do
      get "/#{spanish_language.html_lang}/#{category.slug}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:success)
    end

    it "returns 404 for an unknown locale when request has a mount script_name" do
      get "/xx/#{category.slug}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a default locale prefix when request has a mount script_name" do
      get "/#{default_language.html_lang}/#{category.slug}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end
  end
end

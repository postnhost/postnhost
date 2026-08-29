require "rails_helper"

RSpec.describe "Public::StaticPages", type: :request do
  let!(:default_language) { create(:language, :default, name: "English", html_lang: "en") }
  let!(:spanish_language) { create(:language, name: "Spanish", html_lang: "es", default: false) }
  let!(:user) { create(:user) }

  describe "GET /:slug" do
    it "renders a published dynamic page from its snapshot" do
      create(:page, :published, user:, slug: "dynamic-terms", title: "Dynamic Terms", content: "<p>Dynamic terms body</p>")

      get "/dynamic-terms"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dynamic Terms")
      expect(response.body).to include("Dynamic terms body")
    end

    it "returns 304 for an unchanged dynamic page" do
      create(:page, :published, user:, slug: "dynamic-terms", title: "Dynamic Terms")
      get "/dynamic-terms"
      etag = response.headers.fetch("ETag")

      get "/dynamic-terms", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "falls back to code-defined static template when dynamic page is missing" do
      get "/terms"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Terms page from namespaced static path")
    end

    it "returns 304 for an unchanged code-defined static page" do
      get "/terms"
      etag = response.headers.fetch("ETag")

      get "/terms", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "does not render draft dynamic pages" do
      create(:page, user:, slug: "draft-only", title: "Draft only")

      get "/draft-only"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown static page" do
      get "/definitely-missing-page"

      expect(response).to have_http_status(:not_found)
    end

    it "renders static page when non-default template is active" do
      Postnhost::Template.current.update!(name: "workspace-journal")

      get "/terms"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include("Terms page from namespaced static path")
    end

    it "uses the title tag and custom OG title when present" do
      create(:page, :published, user:, slug: "dynamic-terms", title: "Dynamic Terms",
                                title_tag: "Dynamic Terms | Site", og_title: "Custom Page OG Title")

      get "/dynamic-terms"

      expect(response.body).to include(">Dynamic Terms | Site</title>")
      expect(response.body).to include('<meta property="og:title" content="Custom Page OG Title"')
    end
  end

  describe "GET /:locale/:slug" do
    it "renders static page with locale prefix" do
      get "/es/terms"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Terms page from namespaced static path")
    end

    it "renders the published page variant for the locale" do
      page = create(:page, :published, user:, slug: "privacy", language: default_language,
                                       title: "Privacy", content: "<p>Privacy body</p>")
      create(:page_variant, :published, page:, language: spanish_language,
                                        title: "Privacidad", content: "<p>Cuerpo de privacidad</p>")

      get "/es/privacy"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Privacidad")
      expect(response.body).to include("Cuerpo de privacidad")
      expect(response.body).not_to include("Privacy body")
    end

    it "uses the variant title tag and OG title for the locale" do
      page = create(:page, :published, user:, slug: "privacy", language: default_language,
                                       title: "Privacy", title_tag: "Privacy | Site", og_title: "Privacy OG")
      create(:page_variant, :published, page:, language: spanish_language,
                                        title: "Privacidad", title_tag: "Privacidad | Sitio",
                                        og_title: "Privacidad OG", content: "<p>Cuerpo</p>")

      get "/es/privacy"

      expect(response.body).to include(">Privacidad | Sitio</title>")
      expect(response.body).to include('<meta property="og:title" content="Privacidad OG"')
      expect(response.body).not_to include(">Privacy | Site</title>")
      expect(response.body).not_to include('content="Privacy OG"')
    end

    it "returns 404 for a dynamic page without a published variant in the locale" do
      create(:page, :published, user:, slug: "privacy", language: default_language, title: "Privacy")

      get "/es/privacy"

      expect(response).to have_http_status(:not_found)
    end

    it "renders static page with locale prefix when request has a mount script_name" do
      get "/es/terms", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Terms page from namespaced static path")
    end

    it "returns 404 for unknown locale with a mount script_name" do
      get "/xx/terms", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for default locale prefix with a mount script_name" do
      get "/#{default_language.html_lang}/terms", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end
  end
end

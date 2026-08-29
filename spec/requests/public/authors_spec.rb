require "rails_helper"

RSpec.describe "Public::Authors", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish_language) { create(:language, :spanish) }
  let!(:author) do
    create(
      :user,
      name: "Taylor Writer",
      slug: "taylor-writer",
      bio: "Writes about software craft.",
      website_url: "example.com",
      x_url: "https://x.com/taylorwriter",
      linkedin_url: "https://linkedin.com/in/taylorwriter",
      facebook_url: "https://facebook.com/taylorwriter",
      threads_url: "https://threads.net/@taylorwriter",
      youtube_url: "https://youtube.com/@taylorwriter",
      mastodon_url: "https://mastodon.social/@taylorwriter"
    )
  end

  describe "GET /authors/:slug" do
    it "returns http success" do
      get "/authors/#{author.slug}"

      expect(response).to have_http_status(:success)
    end

    it "returns 304 when the public site is unchanged" do
      get "/authors/#{author.slug}"
      etag = response.headers.fetch("ETag")

      get "/authors/#{author.slug}", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "renders author title, bio, and article snippets for authored and co-authored content" do
      create(:article, :published, user: author, title: "Authored Post")
      coauthored_owner = create(:user)
      coauthored_article = create(:article, :published, user: coauthored_owner, title: "Coauthored Post")
      create(:article_author, article: coauthored_article, user: author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article: coauthored_article)

      get "/authors/#{author.slug}"

      expect(response.body).to include("Taylor Writer")
      expect(response.body).to include("Writes about software craft.")
      expect(response.body).to include("Authored Post")
      expect(response.body).to include("Coauthored Post")
      expect(response.body).to include("https://example.com")
      expect(response.body).to include("https://x.com/taylorwriter")
      expect(response.body).to include("https://linkedin.com/in/taylorwriter")
      expect(response.body).to include("https://facebook.com/taylorwriter")
      expect(response.body).to include("https://threads.net/@taylorwriter")
      expect(response.body).to include("https://youtube.com/@taylorwriter")
      expect(response.body).to include("https://mastodon.social/@taylorwriter")
      expect(response.body).to include('name="description" content="Writes about software craft."')
      expect(response.body).to include('"@type":"Person"')
      expect(response.body).to include("/authors/taylor-writer/#person")
    end

    it "renders cover images in author article cards when available" do
      article = create(:article, :published, user: author, title: "Article With Cover")
      cover_image_path = File.expand_path("../../fixtures/files/cover_image.webp", __dir__)
      article.cover_image = Rack::Test::UploadedFile.new(cover_image_path, "image/webp")
      article.save!
      Postnhost::Publishing::Articles::Publish.call(article:)

      get "/authors/#{author.slug}"

      expect(response.body).to include("Article With Cover")
      expect(response.body).to include("/uploads/postnhost/article/")
    end

    it "renders author pages with the workspace-journal template" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      create(:article, :published, user: author, title: "Workspace Author Post")

      get "/authors/#{author.slug}"

      document = response.parsed_body

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include("Taylor Writer")
      expect(response.body).to include("Workspace Author Post")
      expect(response.body).to include("https://example.com")
      expect(document.css("article").any? { |article_card| article_card.text.include?("Taylor Writer") }).to be(false)

      author_heading = document.at_css("aside h1")
      heading_and_ancestors = [author_heading, *author_heading.ancestors]

      expect(heading_and_ancestors.none? { |node| node["class"].to_s.split.include?("break-words") }).to be(true)
    end

    it "redirects page=1 to canonical author URL" do
      get "/authors/#{author.slug}?page=1"

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("/authors/#{author.slug}")
    end

    it "returns 404 for unknown slug" do
      get "/authors/unknown-author"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)

      get "/authors/#{author.slug}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Routing Error")
      expect(response.body).to include("Not Found")
    end
  end

  describe "GET /:locale/authors/:slug" do
    it "returns http success for a localized author page" do
      get "/#{spanish_language.html_lang}/authors/#{author.slug}"

      expect(response).to have_http_status(:success)
    end

    it "renders localized authored/co-authored snippets" do
      authored_article = create(:article, :published, user: author)
      create(:article_variant, :published, article: authored_article, language: spanish_language, title: "Articulo de Autor")

      coauthored_owner = create(:user)
      coauthored_article = create(:article, :published, user: coauthored_owner)
      create(:article_author, article: coauthored_article, user: author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article: coauthored_article)
      create(:article_variant, :published, article: coauthored_article, language: spanish_language, title: "Articulo Compartido")

      get "/#{spanish_language.html_lang}/authors/#{author.slug}"

      expect(response.body).to include("Articulo de Autor")
      expect(response.body).to include("Articulo Compartido")
      expect(response.body).to include("/#{spanish_language.html_lang}/authors/#{author.slug}")
    end

    it "returns 404 for unknown author in localized route" do
      get "/#{spanish_language.html_lang}/authors/missing-author"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)

      get "/#{spanish_language.html_lang}/authors/#{author.slug}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Routing Error")
      expect(response.body).to include("Not Found")
    end
  end
end

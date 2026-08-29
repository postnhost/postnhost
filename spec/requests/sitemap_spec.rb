require "rails_helper"

RSpec.describe "Sitemap", type: :request do
  let!(:default_language) { create(:language, :default) }

  around do |example|
    original_site_url = Postnhost.config.site_url
    Postnhost.configure { |config| config.site_url = nil }
    example.run
  ensure
    Postnhost.configure { |config| config.site_url = original_site_url }
  end

  describe "GET /sitemap.xml" do
    let!(:spanish) { create(:language, :spanish) }
    let!(:category) { create(:category, slug: "technology") }
    let!(:published_article) { create(:article, :published, language: default_language, slug: "hello-world") }
    let!(:published_variant) { create(:article_variant, :published, article: published_article, language: spanish) }
    let!(:unpublished_article) { create(:article) }
    let!(:published_page) { create(:page, :published, slug: "privacy-policy") }
    let!(:draft_page) { create(:page, slug: "draft-only") }

    before do
      Postnhost::Setting.current.update!(site_url: "https://blog.example.com")
      create(:article_category, article: published_article, category:)
      Postnhost::Publishing::Articles::Publish.call(article: published_article)
    end

    it "returns http success" do
      get "/sitemap.xml"
      expect(response).to have_http_status(:ok)
    end

    it "returns XML content type" do
      get "/sitemap.xml"
      expect(response.content_type).to start_with("application/xml")
    end

    it "is pretty-printed and links an XSL for browsers (optional; crawlers ignore the stylesheet)" do
      get "/sitemap.xml"

      expect(response.body).to include('<?xml-stylesheet type="text/xsl" href="/sitemap.xsl"?>')
      expect(response.body).to include("\n  <url>\n")
    end

    it "includes sitemap and xhtml namespaces" do
      get "/sitemap.xml"

      xml = Nokogiri::XML(response.body)

      expect(xml.root.name).to eq("urlset")
      expect(xml.root.namespaces["xmlns"]).to eq("http://www.sitemaps.org/schemas/sitemap/0.9")
      expect(xml.root.namespaces["xmlns:xhtml"]).to eq("http://www.w3.org/1999/xhtml")
    end

    it "uses the configured canonical host for all sitemap URLs" do
      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)

      expect(locs).to all(start_with("https://blog.example.com"))
    end

    it "uses the request origin when the canonical origin is unconfigured" do
      host! "example.com"
      Postnhost::Setting.current.update_column(:site_url, nil)

      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)
      expect(locs).to all(start_with("http://example.com"))
    end

    it "uses the initializer default when the dashboard origin is blank" do
      Postnhost::Setting.current.update_column(:site_url, nil)
      Postnhost.configure { |config| config.site_url = "https://initializer.example.com" }

      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)
      expect(locs).to all(start_with("https://initializer.example.com"))
    end

    it "includes canonical public URLs without query params" do
      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)

      expect(locs).to include(
        "https://blog.example.com/",
        "https://blog.example.com/technology",
        "https://blog.example.com/hello-world",
        "https://blog.example.com/es",
        "https://blog.example.com/es/technology",
        "https://blog.example.com/es/hello-world",
        "https://blog.example.com/terms"
      )
      expect(locs).not_to include("https://blog.example.com/about", "https://blog.example.com/support")
      expect(locs).not_to include("https://blog.example.com/es/terms")
      expect(locs).to all(satisfy { |loc| URI.parse(loc).query.nil? })
    end

    it "includes hreflang alternates for blog index pages" do
      get "/sitemap.xml"

      root_entry = sitemap_entry_for("https://blog.example.com/")

      expect(alternate_map_for(root_entry)).to eq(
        "en" => "https://blog.example.com/",
        "es" => "https://blog.example.com/es",
        "x-default" => "https://blog.example.com/"
      )
    end

    it "includes hreflang alternates for category pages" do
      get "/sitemap.xml"

      category_entry = sitemap_entry_for("https://blog.example.com/technology")

      expect(alternate_map_for(category_entry)).to eq(
        "en" => "https://blog.example.com/technology",
        "es" => "https://blog.example.com/es/technology",
        "x-default" => "https://blog.example.com/technology"
      )
    end

    it "includes hreflang alternates for article pages" do
      get "/sitemap.xml"

      article_entry = sitemap_entry_for("https://blog.example.com/hello-world")

      expect(alternate_map_for(article_entry)).to eq(
        "en" => "https://blog.example.com/hello-world",
        "es" => "https://blog.example.com/es/hello-world",
        "x-default" => "https://blog.example.com/hello-world"
      )
    end

    it "includes only public article URLs" do
      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)

      expect(locs).to include("https://blog.example.com/hello-world")
      expect(locs).not_to include("https://blog.example.com/#{unpublished_article.slug}")
    end

    it "includes real static pages instead of hardcoded sitemap_base entries" do
      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)

      expect(locs).to include("https://blog.example.com/terms")
      expect(locs).not_to include("https://blog.example.com/about", "https://blog.example.com/support")
    end

    it "includes published dynamic pages only at canonical URLs and excludes draft pages" do
      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)

      expect(locs).to include("https://blog.example.com/privacy-policy")
      expect(locs).not_to include("https://blog.example.com/es/privacy-policy")
      expect(locs).not_to include(
        "https://blog.example.com/draft-only",
        "https://blog.example.com/es/draft-only"
      )
    end

    it "includes hreflang alternates for dynamic pages with published variants" do
      page = create(:page, :published, slug: "about-us", language: default_language)
      create(:page_variant, :published, page:, language: spanish)

      get "/sitemap.xml"

      locs = sitemap_doc.xpath("//xmlns:url/xmlns:loc").map(&:text)
      expect(locs).to include(
        "https://blog.example.com/about-us",
        "https://blog.example.com/es/about-us"
      )

      page_entry = sitemap_entry_for("https://blog.example.com/about-us")
      expect(alternate_map_for(page_entry)).to eq(
        "en" => "https://blog.example.com/about-us",
        "es" => "https://blog.example.com/es/about-us",
        "x-default" => "https://blog.example.com/about-us"
      )
    end

    it "keeps static templates and dynamic pages canonical-only in sitemap alternates" do
      get "/sitemap.xml"

      static_terms = sitemap_entry_for("https://blog.example.com/terms")
      dynamic_page = sitemap_entry_for("https://blog.example.com/privacy-policy")

      expect(alternate_map_for(static_terms)).to eq(
        "en" => "https://blog.example.com/terms",
        "x-default" => "https://blog.example.com/terms"
      )
      expect(alternate_map_for(dynamic_page)).to eq(
        "en" => "https://blog.example.com/privacy-policy",
        "x-default" => "https://blog.example.com/privacy-policy"
      )
    end
  end

  describe "GET /sitemap.xsl" do
    it "returns the XSLT used for optional browser rendering" do
      get "/sitemap.xsl"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("xml")
      expect(response.body).to include("xsl:stylesheet")
      expect(response.body).to include("sitemap:urlset")
    end
  end

  def sitemap_doc
    @sitemap_doc ||= Nokogiri::XML(response.body)
  end

  def sitemap_entry_for(loc)
    sitemap_doc.at_xpath(%(//xmlns:url[xmlns:loc="#{loc}"]))
  end

  def alternate_map_for(entry)
    entry.xpath("xhtml:link", "xhtml" => "http://www.w3.org/1999/xhtml").to_h do |node|
      [node["hreflang"], node["href"]]
    end
  end
end

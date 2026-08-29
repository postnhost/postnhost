require "rails_helper"

RSpec.describe Postnhost::SitemapBuilder do
  let!(:default_language) { create(:language, :default) }
  let(:request) { instance_double(ActionDispatch::Request, script_name:) }
  let(:script_name) { "" }
  let(:site_url) { "https://blog.example.com" }

  describe "#call" do
    it "renders a pretty XML document with sitemap namespaces and a stylesheet link" do
      create(:article, :published, language: default_language, slug: "hello-world")

      xml = described_class.new(request:, site_url:).call
      doc = Nokogiri::XML(xml)

      expect(xml).to include('<?xml-stylesheet type="text/xsl" href="/sitemap.xsl"?>')
      expect(xml).to include("\n  <url>\n")
      expect(doc.root.name).to eq("urlset")
      expect(doc.root.namespaces["xmlns"]).to eq("http://www.sitemaps.org/schemas/sitemap/0.9")
      expect(doc.root.namespaces["xmlns:xhtml"]).to eq("http://www.w3.org/1999/xhtml")
    end

    it "builds hreflang clusters for blog, category, article, and dynamic page URLs" do
      spanish = create(:language, :spanish)
      category = create(:category, slug: "technology")
      article = create(:article, :published, language: default_language, slug: "hello-world")
      page = create(:page, :published, language: default_language, slug: "privacy-policy")

      create(:article_category, article:, category:)
      Postnhost::Publishing::Articles::Publish.call(article:)
      create(:article_variant, :published, article:, language: spanish)
      create(:page_variant, :published, page:, language: spanish)

      doc = sitemap_doc

      expect(locs_for(doc)).to include(
        "https://blog.example.com/",
        "https://blog.example.com/es",
        "https://blog.example.com/technology",
        "https://blog.example.com/es/technology",
        "https://blog.example.com/hello-world",
        "https://blog.example.com/es/hello-world",
        "https://blog.example.com/privacy-policy",
        "https://blog.example.com/es/privacy-policy"
      )
      expect(alternate_map_for(doc, "https://blog.example.com/")).to eq(
        "en" => "https://blog.example.com/",
        "es" => "https://blog.example.com/es",
        "x-default" => "https://blog.example.com/"
      )
      expect(alternate_map_for(doc, "https://blog.example.com/technology")).to eq(
        "en" => "https://blog.example.com/technology",
        "es" => "https://blog.example.com/es/technology",
        "x-default" => "https://blog.example.com/technology"
      )
      expect(alternate_map_for(doc, "https://blog.example.com/hello-world")).to eq(
        "en" => "https://blog.example.com/hello-world",
        "es" => "https://blog.example.com/es/hello-world",
        "x-default" => "https://blog.example.com/hello-world"
      )
      expect(alternate_map_for(doc, "https://blog.example.com/privacy-policy")).to eq(
        "en" => "https://blog.example.com/privacy-policy",
        "es" => "https://blog.example.com/es/privacy-policy",
        "x-default" => "https://blog.example.com/privacy-policy"
      )
    end

    it "excludes unpublished content and keeps static templates canonical-only" do
      spanish = create(:language, :spanish)
      published_article = create(:article, :published, language: default_language, slug: "public-article")
      draft_article = create(:article, language: default_language, slug: "draft-article")
      published_page = create(:page, :published, language: default_language, slug: "published-page")
      draft_page = create(:page, language: default_language, slug: "draft-page")

      create(:article_variant, article: published_article, language: spanish)
      create(:page_variant, page: published_page, language: spanish)

      doc = sitemap_doc
      locs = locs_for(doc)

      expect(locs).to include("https://blog.example.com/public-article", "https://blog.example.com/published-page")
      expect(locs).not_to include(
        "https://blog.example.com/#{draft_article.slug}",
        "https://blog.example.com/es/#{published_article.slug}",
        "https://blog.example.com/#{draft_page.slug}",
        "https://blog.example.com/es/#{published_page.slug}"
      )
      expect(alternate_map_for(doc, "https://blog.example.com/terms")).to eq(
        "en" => "https://blog.example.com/terms",
        "x-default" => "https://blog.example.com/terms"
      )
    end

    context "when the engine is mounted under a script name" do
      let(:script_name) { "/blog" }

      it "prefixes generated paths and the stylesheet link with the script name" do
        create(:article, :published, language: default_language, slug: "mounted-article")

        xml = described_class.new(request:, site_url:).call
        doc = Nokogiri::XML(xml)

        expect(xml).to include('<?xml-stylesheet type="text/xsl" href="/blog/sitemap.xsl"?>')
        expect(locs_for(doc)).to include(
          "https://blog.example.com/blog/",
          "https://blog.example.com/blog/mounted-article"
        )
      end
    end

    context "without a configured default language or published content" do
      before { Postnhost::Language.delete_all }

      it "omits empty blog clusters while retaining canonical static pages" do
        doc = sitemap_doc

        expect(locs_for(doc)).not_to include("https://blog.example.com/")
        expect(locs_for(doc)).to include("https://blog.example.com/terms")
        expect(alternate_map_for(doc, "https://blog.example.com/terms")).to eq(
          "en" => "https://blog.example.com/terms",
          "x-default" => "https://blog.example.com/terms"
        )
      end
    end
  end

  describe "#cache_key" do
    it "includes the host and script name and changes when public sitemap content changes" do
      builder = described_class.new(request:, site_url:)
      initial_key = builder.cache_key

      create(:article, :published, language: default_language, slug: "cache-key-article")

      updated_key = described_class.new(request:, site_url:).cache_key

      expect(initial_key).to include("sitemap_xml_v12", "https://blog.example.com")
      expect(updated_key).not_to eq(initial_key)
    end

    context "when the engine is mounted under a script name" do
      let(:script_name) { "/blog" }

      it "varies by script name" do
        expect(described_class.new(request:, site_url:).cache_key).to include("/blog")
      end
    end
  end

  def sitemap_doc
    Nokogiri::XML(described_class.new(request:, site_url:).call)
  end

  def locs_for(doc)
    doc.xpath("//xmlns:url/xmlns:loc").map(&:text)
  end

  def alternate_map_for(doc, loc)
    entry = doc.at_xpath(%(//xmlns:url[xmlns:loc="#{loc}"]))

    entry.xpath("xhtml:link", "xhtml" => "http://www.w3.org/1999/xhtml").to_h do |node|
      [node["hreflang"], node["href"]]
    end
  end
end

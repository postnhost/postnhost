require "rails_helper"

RSpec.describe Postnhost::SeoHelper, type: :helper do
  before do
    helper.define_singleton_method(:current_setting) { Postnhost::Setting.current }
  end

  describe "#page_title" do
    it "returns the blog meta title by default" do
      expect(helper.page_title).to eq(I18n.t("postnhost.public.site.blog_meta_title"))
    end

    it "returns content_for title when provided" do
      helper.content_for(:title, "Custom Title")

      expect(helper.page_title).to eq("Custom Title")
    end
  end

  describe "#page_description" do
    it "returns translated site description by default" do
      expect(helper.page_description).to eq(I18n.t("postnhost.public.site.blog_meta_description"))
    end

    it "returns content_for meta_description when provided" do
      helper.content_for(:meta_description, "Custom Description")

      expect(helper.page_description).to eq("Custom Description")
    end

    it "returns nil on paginated public index pages" do
      allow(helper).to receive_messages(controller_name: "articles", action_name: "index", params: { page: "2" })

      expect(helper.page_description).to be_nil
    end
  end

  describe "#og_title" do
    it "falls back to page title when custom og title is not provided" do
      helper.content_for(:title, "Fallback SEO Title")

      expect(helper.og_title).to eq("Fallback SEO Title")
    end

    it "uses custom og title when provided" do
      helper.content_for(:og_title, "Custom OG Title")

      expect(helper.og_title).to eq("Custom OG Title")
    end
  end

  describe "#schema_headline" do
    it "falls back to page title when schema headline is not provided" do
      helper.content_for(:title, "Fallback Schema Title")

      expect(helper.schema_headline).to eq("Fallback Schema Title")
    end

    it "uses custom schema headline when provided" do
      helper.content_for(:schema_headline, "Custom Schema Headline")

      expect(helper.schema_headline).to eq("Custom Schema Headline")
    end
  end

  describe "#canonical_url" do
    it "uses the configured site origin and removes query params and trailing slash" do
      Postnhost::Setting.current.update!(site_url: "https://canonical.example.com")
      helper.content_for(:url, "https://request.example.com/path/?utm=1")

      expect(helper.canonical_url).to eq("https://canonical.example.com/path")
    end
  end

  describe "#robots_content" do
    it "defaults to index, follow" do
      expect(helper.robots_content).to eq("index, follow")
    end

    it "uses content_for robots when provided" do
      helper.content_for(:robots, "noindex, nofollow")

      expect(helper.robots_content).to eq("noindex, nofollow")
    end

    it "uses noindex for the whole site when search indexing is disabled" do
      Postnhost::Setting.current.update!(site_indexing: "noindex")
      helper.content_for(:robots, "index, follow")

      expect(helper.robots_content).to eq("noindex, nofollow")
    end
  end

  describe "#article_schema" do
    it "returns nil for nil article" do
      expect(helper.article_schema(nil)).to be_nil
    end

    it "returns nil for unpublished article" do
      article = instance_double(Postnhost::Snapshot::Article, published_at: nil)

      expect(helper.article_schema(article)).to be_nil
    end

    it "builds multi-author schema data for a published article without image" do
      first_author = create(:user, name: "Jane Doe", slug: "jane-doe", position: "Editor", bio: "Writes about product.")
      second_author = create(:user, name: "John Smith", slug: "john-smith", position: "Reporter", bio: "Covers dev tools.")
      category = create(:category, name: "Tech")
      article = create(
        :article,
        :published,
        user: first_author,
        updated_at: Time.zone.parse("2025-01-02 11:00:00"),
        cover_image: nil
      )
      create(:article_category, article:, category:)
      create(:article_author, article:, user: second_author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article:)

      helper.content_for(:title, "Schema Title")
      helper.content_for(:schema_headline, "Custom Headline for Schema")
      helper.content_for(:meta_description, "Schema Description")
      helper.content_for(:url, "https://example.com/articles/schema-title")
      helper.content_for(:lang, "en")

      schema = helper.article_schema(article.article_snapshot)

      expect(schema["@type"]).to eq("BlogPosting")
      expect(schema["headline"]).to eq("Custom Headline for Schema")
      expect(schema["description"]).to eq("Schema Description")
      expect(schema["author"].length).to eq(2)
      expect(schema["author"].first["name"]).to eq("Jane Doe")
      expect(schema["author"].second["name"]).to eq("John Smith")
      expect(schema["author"].first["@id"]).to include("/authors/jane-doe/#person")
      expect(schema["author"].second["@id"]).to include("/authors/john-smith/#person")
      expect(schema["publisher"]).to include("@id")
      expect(schema["publisher"]).not_to have_key("logo")
      expect(schema["articleSection"]).to eq("Tech")
      expect(schema["inLanguage"]).to eq("en")
      expect(schema).not_to have_key("image")
    end

    it "omits author profile URL fields when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)
      author = create(:user, name: "Jane Doe", slug: "jane-doe")
      article = create(:article, :published, user: author)
      helper.content_for(:lang, "en")

      schema = helper.article_schema(article.article_snapshot)

      expect(schema["author"].first["name"]).to eq("Jane Doe")
      expect(schema["author"].first).not_to have_key("@id")
      expect(schema["author"].first).not_to have_key("url")
    end

    it "includes image data when article has a cover image" do
      user = create(:user, name: "Jane Doe", slug: "jane-doe")
      image = double(url: "https://cdn.example.com/cover.jpg")
      article = create(:article, :published, user:)
      allow(article.article_snapshot).to receive_messages(cover_image?: true, cover_image: image)

      helper.content_for(:lang, "en")

      schema = helper.article_schema(article.article_snapshot)

      expect(schema["image"]).to include(
        "@type" => "ImageObject",
        "url" => "https://cdn.example.com/cover.jpg",
        "width" => 1200,
        "height" => 630
      )
    end

    it "uses site default schema type and allows article override" do
      setting = Postnhost::Setting.current
      setting.update!(schema_settings: { "default_article_type" => "Report" })
      article = create(:article, :published, schema_article_type: nil)
      helper.content_for(:lang, "en")

      schema = helper.article_schema(article.article_snapshot)
      expect(schema["@type"]).to eq("Report")

      article.update!(schema_article_type: "TechArticle")
      Postnhost::Publishing::Articles::Publish.call(article:)
      expect(helper.article_schema(article.article_snapshot)["@type"]).to eq("TechArticle")
    end
  end

  describe "#author_schema" do
    it "builds person schema with canonical author URL and profile fields" do
      author = create(:user, name: "Schema Author", slug: "schema-author", position: "Editor", bio: "Bio text")
      allow(helper).to receive(:author_avatar).with(author).and_return("https://cdn.example.com/avatar.jpg")

      schema = helper.author_schema(author)

      expect(schema["@type"]).to eq("Person")
      expect(schema["@id"]).to include("/authors/schema-author/#person")
      expect(schema["name"]).to eq("Schema Author")
      expect(schema["jobTitle"]).to eq("Editor")
      expect(schema["description"]).to eq("Bio text")
      expect(schema["url"]).to include("/authors/schema-author/")
      expect(schema["image"]).to include("url" => "https://cdn.example.com/avatar.jpg", "width" => 128, "height" => 128)
      expect(schema["worksFor"]["@id"]).to include("/#organization")
    end

    it "uses localized author schema overrides when present" do
      author = create(
        :user,
        name: "Schema Author",
        slug: "schema-author",
        position: "Editor",
        bio: "Base bio",
        schema_profile: {
          "same_as" => [
            "https://twitter.com/schema-author",
            "https://linkedin.com/in/schema-author"
          ],
          "knows_language" => %w[en de],
          "alumni_type" => "CollegeOrUniversity",
          "image_url" => "https://cdn.example.com/override.jpg"
        },
        schema_locale_overrides: {
          "de" => {
            "name" => "Schema Autor",
            "job_title" => "Chefredakteur",
            "bio" => "Lokalisierte bio",
            "knows_about" => "Politics\nTech",
            "awards" => "Pulitzer",
            "alumni_of" => "Berlin University"
          }
        }
      )
      helper.content_for(:lang, "de")

      schema = helper.author_schema(author)

      expect(schema["name"]).to eq("Schema Autor")
      expect(schema["jobTitle"]).to eq("Chefredakteur")
      expect(schema["description"]).to eq("Lokalisierte bio")
      expect(schema["sameAs"]).to eq(["https://twitter.com/schema-author", "https://linkedin.com/in/schema-author"])
      expect(schema["knowsAbout"]).to eq(%w[Politics Tech])
      expect(schema["knowsLanguage"]).to eq(%w[en de])
      expect(schema["awards"]).to eq(["Pulitzer"])
      expect(schema["alumniOf"]).to include("@type" => "CollegeOrUniversity", "name" => "Berlin University")
      expect(schema["image"]).to include("url" => "https://cdn.example.com/override.jpg")
    end

    it "omits person profile URL fields when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)
      author = create(:user, name: "Schema Author", slug: "schema-author", position: "Editor", bio: "Bio text")

      schema = helper.author_schema(author)

      expect(schema["@type"]).to eq("Person")
      expect(schema["name"]).to eq("Schema Author")
      expect(schema).not_to have_key("@id")
      expect(schema).not_to have_key("url")
    end

    it "syncs profile social links into author sameAs" do
      author = create(
        :user,
        slug: "social-author",
        website_url: "example.com",
        x_url: "https://x.com/social-author",
        linkedin_url: "linkedin.com/in/social-author",
        facebook_url: "https://facebook.com/social-author",
        youtube_url: "https://youtube.com/@social-author",
        instagram_url: "https://instagram.com/social-author",
        threads_url: "https://threads.net/@social-author",
        tiktok_url: "https://tiktok.com/@social-author",
        mastodon_url: "https://mastodon.social/@social-author",
        bluesky_url: "https://bsky.app/profile/social-author",
        schema_profile: {
          "same_as" => ["https://custom.example.com/profile", "https://x.com/social-author"]
        }
      )

      schema = helper.author_schema(author)

      expect(schema["sameAs"]).to eq(
        [
          "https://custom.example.com/profile",
          "https://x.com/social-author",
          "https://example.com",
          "https://linkedin.com/in/social-author",
          "https://facebook.com/social-author",
          "https://youtube.com/@social-author",
          "https://instagram.com/social-author",
          "https://threads.net/@social-author",
          "https://tiktok.com/@social-author",
          "https://mastodon.social/@social-author",
          "https://bsky.app/profile/social-author"
        ]
      )
    end
  end

  describe "#website_schema" do
    it "uses schema settings for organization and website nodes" do
      setting = Postnhost::Setting.current
      setting.update!(
        schema_settings: {
          "organization_type" => "Organization",
          "contact_email" => "editor@example.com",
          "contact_type" => "editorial",
          "same_as" => ["https://x.com/postnhost"],
          "policies" => { "ethics_policy" => "https://example.com/ethics" }
        }
      )
      helper.content_for(:lang, "en")

      website = helper.website_schema
      organization = helper.send(:schema_organization_node)
      publisher = helper.organization_schema

      expect(website["name"]).to eq(I18n.t("postnhost.public.site.schema_site_name"))
      expect(website).not_to have_key("image")
      expect(organization["@type"]).to eq("Organization")
      expect(website["publisher"]).to eq({ "@id" => organization["@id"] })
      expect(publisher["logo"]).to include("@type" => "ImageObject")
      expect(organization["contactPoint"]).to include("email" => "editor@example.com", "contactType" => "editorial")
      expect(organization["sameAs"]).to eq(["https://x.com/postnhost"])
      expect(organization["ethicsPolicy"]).to eq("https://example.com/ethics")
    end

    it "renders expected defaults when schema fields are empty" do
      setting = Postnhost::Setting.current
      setting.update!(schema_settings: {}, schema_locale_overrides: {})
      helper.content_for(:lang, "en")

      website = helper.website_schema
      organization = helper.send(:schema_organization_node)
      article = create(:article, :published, schema_article_type: nil)
      article_schema = helper.article_schema(article.article_snapshot)

      expect(organization["@type"]).to eq("Organization")
      expect(article_schema["@type"]).to eq("BlogPosting")
      expect(organization).not_to have_key("alternateName")
      expect(organization).not_to have_key("contactPoint")
      expect(organization).not_to have_key("sameAs")
      expect(website["name"]).to eq(I18n.t("postnhost.public.site.schema_site_name"))
      expect(website).not_to have_key("image")
    end

    it "renders all added schema fields" do
      setting = Postnhost::Setting.current
      setting.update!(
        schema_settings: {
          "organization_type" => "Corporation",
          "founding_date" => "01/01/2020",
          "founding_location" => "Dnipro, UA",
          "contact_email" => "press@example.com",
          "contact_type" => "press",
          "address" => "Main Street 1",
          "address_city" => "Dnipro",
          "address_country" => "UA",
          "default_article_type" => "Report",
          "coverage_starts_at" => "2020-01-01",
          "coverage_ends_at" => "2030-01-01",
          "same_as" => ["https://x.com/postnhost", "https://linkedin.com/company/postnhost"],
          "policies" => {
            "publishing_principles" => "https://example.com/publishing",
            "corrections_policy" => "https://example.com/corrections"
          }
        },
        schema_locale_overrides: {
          "en" => {
            "website_name" => "PostnHost Media",
            "website_description" => "Long form publication",
            "organization_name" => "PostnHost Corp",
            "organization_alternate_name" => "PH",
            "organization_description" => "Corporate newsroom"
          }
        }
      )
      helper.content_for(:lang, "en")

      website = helper.website_schema
      organization = helper.send(:schema_organization_node)
      article = create(:article, :published, schema_article_type: nil)

      expect(website["name"]).to eq("PostnHost Media")
      expect(website["description"]).to eq("Long form publication")
      expect(website).not_to have_key("image")
      expect(organization["@type"]).to eq("Corporation")
      expect(organization["name"]).to eq("PostnHost Corp")
      expect(organization["alternateName"]).to eq("PH")
      expect(organization["description"]).to eq("Corporate newsroom")
      expect(organization["foundingDate"]).to eq("01/01/2020")
      expect(organization["foundingLocation"]).to eq("Dnipro, UA")
      expect(organization["contactPoint"]).to include("email" => "press@example.com", "contactType" => "press")
      expect(organization["address"]).to include("streetAddress" => "Main Street 1", "addressLocality" => "Dnipro", "addressCountry" => "UA")
      expect(organization["sameAs"]).to eq(["https://x.com/postnhost", "https://linkedin.com/company/postnhost"])
      expect(organization["publishingPrinciples"]).to eq("https://example.com/publishing")
      expect(organization["correctionsPolicy"]).to eq("https://example.com/corrections")
      expect(organization["coverageStartTime"]).to eq("2020-01-01")
      expect(organization["coverageEndTime"]).to eq("2030-01-01")
      expect(helper.article_schema(article.article_snapshot)["@type"]).to eq("Report")
    end

    it "renders changed values after schema settings updates" do
      setting = Postnhost::Setting.current
      setting.update!(
        schema_settings: {
          "organization_type" => "Organization",
          "default_article_type" => "BlogPosting"
        },
        schema_locale_overrides: {
          "en" => {
            "organization_alternate_name" => "Old Name"
          }
        }
      )

      setting.update!(
        schema_settings: setting.schema_settings.merge(
          "organization_type" => "NGO",
          "default_article_type" => "TechArticle"
        ),
        schema_locale_overrides: setting.schema_locale_overrides.merge(
          "en" => setting.schema_locale_overrides.fetch("en", {}).merge("organization_alternate_name" => "New Name")
        )
      )
      helper.content_for(:lang, "en")

      organization = helper.send(:schema_organization_node)
      article = create(:article, :published, schema_article_type: nil)

      expect(organization["@type"]).to eq("NGO")
      expect(organization["alternateName"]).to eq("New Name")
      expect(helper.article_schema(article.article_snapshot)["@type"]).to eq("TechArticle")
    end
  end

  describe "#structured_data_graph" do
    it "includes website, organization, article, and breadcrumbs on article pages" do
      author = create(:user, slug: "author-a")
      article = create(:article, :published, user: author)
      helper.content_for(:lang, "en")
      helper.content_for(:title, "Article Title")
      helper.content_for(:url, "https://example.com/article-title")

      graph = helper.structured_data_graph(article: article.article_snapshot, author: nil, category: nil)
      nodes = graph.fetch("@graph")
      node_types = nodes.pluck("@type")
      article_types = %w[BlogPosting Article]
      organization_id = helper.send(:schema_organization_id)
      organization_nodes = nodes.select { |node| node["@id"] == organization_id }
      website_node = nodes.find { |node| node["@type"] == "WebSite" }

      expect(node_types).to include("WebSite", "Organization", "BreadcrumbList")
      expect(nodes.any? { |node| article_types.include?(node["@type"]) }).to be(true)
      expect(organization_nodes.size).to eq(1)
      expect(website_node["publisher"]).to eq({ "@id" => organization_id })
    end

    it "includes website, organization, person, and breadcrumbs on author pages" do
      author = create(:user, slug: "author-a")
      helper.content_for(:lang, "en")
      helper.content_for(:title, "Author A")
      helper.content_for(:url, "https://example.com/authors/author-a")

      graph = helper.structured_data_graph(article: nil, author:, category: nil)
      nodes = graph.fetch("@graph")
      node_types = nodes.pluck("@type")

      expect(node_types).to include("WebSite", "Organization", "Person", "BreadcrumbList")
    end

    it "includes website, organization, and breadcrumbs on static/category/index pages" do
      helper.content_for(:lang, "en")
      helper.content_for(:url, "https://example.com/about")

      graph = helper.structured_data_graph(article: nil, author: nil, category: nil)
      nodes = graph.fetch("@graph")
      node_types = nodes.pluck("@type")

      expect(node_types).to include("WebSite", "Organization", "BreadcrumbList")
      expect(node_types).not_to include("Person")
    end
  end

  describe "#breadcrumbs_schema" do
    it "builds breadcrumb items for article with category" do
      category = instance_double(Postnhost::Category, name: "Dev", slug: "dev")
      article = instance_double(Postnhost::Article, categories: [category])

      helper.content_for(:title, "Article Title")
      helper.content_for(:url, "https://example.com/article-title")

      schema = helper.breadcrumbs_schema(article, nil)
      items = schema["itemListElement"]

      expect(items.length).to eq(3)
      expect(items.first["name"]).to eq(I18n.t("postnhost.public.breadcrumbs.home"))
      expect(items.second["name"]).to eq("Dev")
      expect(items.third["name"]).to eq("Article Title")
    end

    it "builds breadcrumb items for category-only page" do
      category = instance_double(Postnhost::Category, name: "News")
      helper.content_for(:url, "https://example.com/news")

      schema = helper.breadcrumbs_schema(nil, category)
      items = schema["itemListElement"]

      expect(items.length).to eq(2)
      expect(items.last["name"]).to eq("News")
    end
  end

  describe "#structured_data_script" do
    it "renders a JSON-LD script tag with id" do
      html = helper.structured_data_script({ "@type" => "WebSite" }, id: "schema-test")

      expect(html).to include('type="application/ld+json"')
      expect(html).to include('id="schema-test"')
      expect(html).to include('"@type":"WebSite"')
    end
  end
end

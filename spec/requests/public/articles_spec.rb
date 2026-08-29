require "rails_helper"

RSpec.describe "Public::Articles", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:published_article) { create(:article, :published) }
  let!(:unpublished_article) { create(:article) }
  let!(:language) { create(:language, :spanish) }

  describe "GET /" do
    it "renders custom header and footer navigation when auto mode is disabled" do
      setting = Postnhost::Setting.current
      setting.update!(use_auto_header_navigation: false, use_auto_footer_navigation: false)
      navigation = setting.current_navigation

      navigation.replace_tree!(
        locale_key: "en",
        tree: {
          "header" => [
            { "id" => -1, "kind" => "link", "label" => "External Docs", "target_kind" => "external", "url" => "https://example.com/docs", "nofollow" => true, "children" => [] }
          ],
          "footer" => [
            { "id" => -2, "kind" => "column", "label" => "Company", "children" => [
              { "id" => -3, "kind" => "link", "label" => "Terms", "target_kind" => "static_page", "target_slug" => "terms", "children" => [] }
            ] }
          ]
        }
      )

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("External Docs")
      expect(response.body).to include("href=\"https://example.com/docs\"")
      expect(response.body).to include("rel=\"noopener noreferrer nofollow\"")
      expect(response.body).to include("Company")
      expect(response.body).to include("href=\"/terms\"")
    end

    it "renders custom header links in swiss-editorial template when auto mode is disabled" do
      Postnhost::Template.current.update!(name: "swiss-editorial")
      setting = Postnhost::Setting.current
      setting.update!(use_auto_header_navigation: false)
      setting.current_navigation.replace_tree!(
        locale_key: "en",
        tree: {
          "header" => [
            { "id" => -1, "kind" => "link", "label" => "About", "target_kind" => "static_page", "target_slug" => "terms", "children" => [] }
          ],
          "footer" => []
        }
      )

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("About")
      expect(response.body).to include("href=\"/terms\"")
    end

    it "renders custom header links in workspace-journal template when auto mode is disabled" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      sidebar_category = create(:category, name: "Workspace Sidebar Category", slug: "workspace-sidebar-category")
      setting = Postnhost::Setting.current
      setting.update!(use_auto_header_navigation: false)
      setting.current_navigation.replace_tree!(
        locale_key: "en",
        tree: {
          "header" => [
            { "id" => -1, "kind" => "link", "label" => "Workspace About", "target_kind" => "static_page", "target_slug" => "terms", "children" => [] }
          ],
          "footer" => []
        }
      )

      get "/"

      document = response.parsed_body

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Workspace About")
      expect(response.body).to include("href=\"/terms\"")
      expect(document.at_css("aside a[href='/#{sidebar_category.slug}']")).to be_nil
      expect(document.at_css("body > header a[href='/#{sidebar_category.slug}']")).to be_nil
    end

    it "does not render automatic categories in the workspace-journal header" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      category = create(:category, name: "Automatic Header Category", slug: "automatic-header-category")
      create(:article_category, article: published_article, category:)
      Postnhost::Publishing::Articles::Publish.call(article: published_article)

      get "/"

      header = response.parsed_body.at_css("body > header")

      expect(response).to have_http_status(:success)
      expect(header.css("a[href='/automatic-header-category']")).to be_empty
      expect(header.css("[aria-label='Toggle navigation']")).to be_empty
      expect(response.body).to include("Automatic Header Category")
    end

    it "does not render automatic categories in the default header" do
      category = create(:category, name: "Automatic Default Header Category", slug: "automatic-default-header-category")
      create(:article_category, article: published_article, category:)
      Postnhost::Publishing::Articles::Publish.call(article: published_article)

      get "/"

      header = response.parsed_body.at_css("body > header")

      expect(response).to have_http_status(:success)
      expect(header.css("a[href='/automatic-default-header-category']")).to be_empty
      expect(header.css("[aria-label='Toggle navigation']")).to be_empty
      expect(header.css("[data-controller='public-mobile-nav']")).to be_empty
      expect(response.body).to include("Automatic Default Header Category")
    end

    it "renders script, meta, and link tags in the public head section" do
      setting = Postnhost::Setting.current
      setting.site_scripts.create!(
        placement: "head",
        script: '<script src="https://example.com/head-first.js" async></script>'
      )
      setting.site_scripts.create!(
        placement: "head",
        script: "<script>console.log('inline')</script>"
      )
      setting.site_scripts.create!(
        placement: "head",
        script: '<meta name="x-test-meta" content="value">'
      )
      setting.site_scripts.create!(
        placement: "head",
        script: '<link rel="preconnect" href="https://cdn.example.com">'
      )

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('src="https://example.com/head-first.js"')
      expect(response.body).to include("console.log('inline')")
      expect(response.body).to include('name="x-test-meta"')
      expect(response.body).to include('content="value"')
      expect(response.body).to include('rel="preconnect"')
      expect(response.body).to include('href="https://cdn.example.com"')

      head_close = response.body.index("</head>")
      script_index = response.body.index('src="https://example.com/head-first.js"')
      inline_index = response.body.index("console.log('inline')")
      meta_index = response.body.index('name="x-test-meta"')
      link_index = response.body.index('rel="preconnect"')

      expect(script_index).to be_present
      expect(inline_index).to be_present
      expect(meta_index).to be_present
      expect(link_index).to be_present
      expect(head_close).to be_present
      expect(script_index).to be < inline_index
      expect(inline_index).to be < meta_index
      expect(meta_index).to be < link_index
      expect(link_index).to be < head_close
    end

    it "renders using selected public template" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      category = create(:category, name: "Workspace Category", slug: "workspace-category")
      create(:article_category, article: published_article, category:)
      Postnhost::Publishing::Articles::Publish.call(article: published_article)

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include("lg:grid-cols-[260px_minmax(0,1fr)]")
      expect(response.body).to include("md:grid-cols-2")
      expect(response.body).to include(I18n.t("postnhost.public.site.blog_subtitle"))
      expect(response.body).to include("Workspace Category")
      expect(response.body).to include(published_article.title)
    end

    it "uses preview_template for authenticated CMS previews without saving it" do
      user = create(:user)
      sign_in user
      Postnhost::Template.current.update!(name: "default")

      get "/?preview_template=workspace-journal"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include("href=\"/#{published_article.slug}?preview_template=workspace-journal\"")
      expect(response.body).to include("value=\"/#{language.html_lang}?preview_template=workspace-journal\"")
      expect(Postnhost::Template.current.reload.name).to eq("default")
    end

    it "ignores preview_template for public visitors" do
      Postnhost::Template.current.update!(name: "default")

      get "/?preview_template=workspace-journal"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Illustration for #{published_article.title}")
      expect(response.body).not_to include("href=\"/#{published_article.slug}?preview_template=workspace-journal\"")
    end

    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "reuses revision-keyed automatic navigation data across requests" do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(Postnhost::Category).to receive(:with_category_variants_for_language).and_call_original

      2.times { get "/" }

      expect(Postnhost::Category).to have_received(:with_category_variants_for_language).once
    end

    it "does not link the empty state back to the current root page" do
      published_article.destroy!

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        link_texts = response.parsed_body.css("a").map { |link| link.text.strip }

        aggregate_failures template_name do
          expect(response).to have_http_status(:success)
          expect(response.body).to include(I18n.t("postnhost.public.blog.no_articles"))
          expect(link_texts).not_to include(I18n.t("postnhost.public.blog.browse_all_articles"))
        end
      end
    end

    it "shows published articles" do
      get "/"
      expect(response.body).to include(published_article.title)
    end

    it "renders every script placement in every public template" do
      setting = Postnhost::Setting.current
      setting.site_scripts.create!(
        placement: "head",
        script: '<meta name="layout-head-marker" content="present">'
      )
      setting.site_scripts.create!(
        placement: "body_start",
        script: '<noscript data-location="body-start">Analytics requires JavaScript</noscript>'
      )
      setting.site_scripts.create!(
        placement: "body_end",
        script: '<script src="https://example.com/body-end.js"></script>'
      )

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        body = response.body
        head_index = body.index('name="layout-head-marker"')
        head_close = body.index("</head>")
        body_open = body.index("<body")
        body_open_close = body.index(">", body_open)
        body_start_index = body.index('data-location="body-start"')
        header_index = body.index("<header")
        footer_index = body.index("</footer")
        body_end_index = body.index('src="https://example.com/body-end.js"')
        body_close = body.index("</body>")

        aggregate_failures template_name do
          expect(response).to have_http_status(:success)
          expect(head_index).to be < head_close
          expect(body_start_index).to be > body_open_close
          expect(body_start_index).to be < header_index
          expect(body_end_index).to be > footer_index
          expect(body_end_index).to be < body_close
        end
      end
    end

    it "renders Top Picks block articles on the default-language index" do
      top_pick_article = create(
        :article,
        :published,
        language: default_language,
        title: "Default Top Pick",
        top_pick: true
      )

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("postnhost.public.blog.top_picks"))
      expect(response.body).to include(top_pick_article.title)
    end

    it "renders workspace-journal Top Picks before the article grid" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      create(
        :article,
        :published,
        language: default_language,
        title: "Workspace Leading Pick",
        top_pick: true
      )

      get "/"

      expect(response).to have_http_status(:success)
      expect(response.body.index(I18n.t("postnhost.public.blog.top_picks"))).to be < response.body.index(published_article.title)
    end

    it "does not render the Top Picks block on the search page" do
      create(:article, :published, language: default_language, title: "Search Top Pick", top_pick: true)

      get "/search"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include(I18n.t("postnhost.public.blog.top_picks"))
    end

    it "shows default blog heading and subtitle when search is closed" do
      get "/"

      expect(response.body).to include(I18n.t("postnhost.public.site.blog_tagline"))
      expect(response.body).to include(I18n.t("postnhost.public.site.blog_subtitle"))
      expect(response.body).to include('href="/search"')
      expect(response.body).not_to include('id="public-blog-search"')
    end

    it "does not treat an empty s query as search results" do
      get "/?s="

      expect(response.body).to include(I18n.t("postnhost.public.site.blog_tagline"))
      expect(response.body).to include(I18n.t("postnhost.public.site.blog_subtitle"))
      expect(response.body).not_to include('id="public-blog-search"')
      expect(response.body).not_to include(I18n.t("postnhost.public.search.heading", query: ""))
      expect(response.body).not_to include('name="robots" content="noindex, nofollow"')
    end

    it "renders search page with form when visiting /search" do
      get "/search"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('id="public-blog-search"')
      expect(response.body).to include(I18n.t("postnhost.public.search.submit"))
      expect(response.body).to include('name="robots" content="noindex, nofollow"')
      expect(response.body).not_to include('<p class="text-lg text-gray-600 max-w-3xl mx-auto leading-relaxed">')
      expect(response.body).to include(published_article.title)
    end

    it "hides search links in every public template when search is disabled" do
      Postnhost::Setting.current.update!(search_enabled: false)

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        aggregate_failures template_name do
          expect(response).to have_http_status(:success)
          expect(response.parsed_body.css("a[href='/search']")).to be_empty
        end
      end
    end

    it "returns 404 for search when search is disabled" do
      Postnhost::Setting.current.update!(search_enabled: false)

      get "/search?s=#{published_article.title}"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Routing Error")
      expect(response.body).to include("Not Found")
    end

    it "invalidates the public page ETag when search is disabled" do
      get "/"
      enabled_etag = response.headers.fetch("ETag")

      Postnhost::Setting.current.update!(search_enabled: false)
      get "/", headers: { "HTTP_IF_NONE_MATCH" => enabled_etag }

      expect(response).to have_http_status(:success)
      expect(response.headers.fetch("ETag")).not_to eq(enabled_etag)
    end

    it "returns 304 for unchanged search results" do
      get "/search?s=#{published_article.title}"
      etag = response.headers.fetch("ETag")

      get "/search?s=#{published_article.title}", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "renders workspace-journal search results in a three-column desktop grid" do
      Postnhost::Template.current.update!(name: "workspace-journal")

      get "/search"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("xl:grid-cols-3")
      expect(response.body).to include(published_article.title)
    end

    it "does not show unpublished articles" do
      get "/"
      expect(response.body).not_to include(unpublished_article.title)
    end

    it "renders uploaded branding assets in the public header and seo tags" do
      setting = Postnhost::Setting.current

      allow(Postnhost::Setting).to receive(:current).and_return(setting)
      allow(setting).to receive_messages(
        site_logo?: true,
        site_logo: double(url: "https://cdn.example.com/site-logo.webp"),
        og_image?: true,
        og_image: double(url: "https://cdn.example.com/default-og.webp")
      )

      get "/"

      expect(response.body).to include("https://cdn.example.com/site-logo.webp")
      expect(response.body).to include('property="og:image" content="https://cdn.example.com/default-og.webp"')
      expect(response.body).to include('name="twitter:image" content="https://cdn.example.com/default-og.webp"')
    end

    it "keeps draft author reassignment private until republish" do
      old_author = create(:user, name: "Card Old Author", slug: "card-old-author")
      new_author = create(:user, name: "Card New Author", slug: "card-new-author")
      article = create(:article, :published, user: old_author, language: default_language, title: "Card Author Article")
      article.article_authors.destroy_all
      create(:article_author, article:, user: new_author, position: 1)

      get "/"

      expect(response.body).to include("Card Old Author")
      expect(response.body).not_to include("Card New Author")
    end

    context "with pagination" do
      let!(:extra_articles) { create_list(:article, 20, :published) }

      it "shows first page with up to 15 articles" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(Postnhost::Article.published.count).to be > 15
      end

      it "shows second page with remaining articles" do
        get "/?page=2"
        expect(response).to have_http_status(:success)
      end

      it "exposes unavailable pagination links with valid ARIA semantics in every template" do
        Postnhost::Template::NAMES.each do |template_name|
          Postnhost::Template.current.update!(name: template_name)

          get "/"
          first_page = response.parsed_body

          get "/?page=2"
          last_page = response.parsed_body

          aggregate_failures template_name do
            expect(first_page.at_css('span[role="link"][aria-label="Previous"][aria-disabled="true"]')).to be_present
            expect(last_page.at_css('span[role="link"][aria-label="Next"][aria-disabled="true"]')).to be_present
          end
        end
      end

      it "omits description meta tags on paginated pages" do
        get "/?page=2"

        expect(response.body).not_to include('name="description"')
        expect(response.body).not_to include('property="og:description"')
        expect(response.body).not_to include('name="twitter:description"')
      end

      it "redirects page=1 to the canonical first page URL" do
        get "/?page=1"

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/")
      end

      it "redirects page=1 while preserving other query params" do
        get "/?page=1&utm_source=newsletter"

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/?utm_source=newsletter")
      end
    end

    context "with search" do
      it "filters published articles by title" do
        matched_article = create(
          :article,
          :published,
          language: default_language,
          title: "Title Needle Search Match"
        )
        unmatched_article = create(
          :article,
          :published,
          language: default_language,
          title: "Completely Different Title"
        )

        get "/search?s=Needle Search"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(matched_article.title)
        expect(response.body).not_to include(unmatched_article.title)
      end

      it "filters published articles by content" do
        matched_article = create(
          :article,
          :published,
          language: default_language,
          title: "Content Search Match",
          content: "<p>Unique body needle marker</p>"
        )
        unmatched_article = create(
          :article,
          :published,
          language: default_language,
          title: "Other Content Article",
          content: "<p>Nothing relevant here</p>"
        )

        get "/search?s=needle marker"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(matched_article.title)
        expect(response.body).not_to include(unmatched_article.title)
      end

      it "renders noindex robots meta and search title/heading" do
        get "/search?s=my query"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('name="robots" content="noindex, nofollow"')
        expect(response.body).to include(I18n.t("postnhost.public.search.title", query: "my query"))
        expect(response.body).to include(I18n.t("postnhost.public.search.heading", query: "my query"))
        expect(response.body).to include('id="public-blog-search"')
        expect(response.body).to include('value="my query"')
      end
    end
  end

  describe "GET /:slug" do
    it "returns http success for published article" do
      get "/#{published_article.slug}"
      expect(response).to have_http_status(:success)
    end

    it "returns 304 when the article is unchanged" do
      get "/#{published_article.slug}"
      etag = response.headers.fetch("ETag")

      get "/#{published_article.slug}", headers: { "HTTP_IF_NONE_MATCH" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "shows the published article content" do
      get "/#{published_article.slug}"
      expect(response.body).to include(published_article.title)
    end

    it "renders syntax-highlighted code without a public JavaScript highlighter" do
      article = create(
        :article,
        :published,
        language: default_language,
        content: '<pre><code class="language-ruby">def publish\n  puts &quot;ready&quot;\nend</code></pre>'
      )

      get "/#{article.slug}"

      code_block = response.parsed_body.at_css("code.language-ruby")
      expect(response).to have_http_status(:success)
      expect(code_block.at_css(".k").text).to eq("def")
      expect(code_block.at_css(".nb").text).to eq("puts")
    end

    it "renders published article pages with the workspace-journal template" do
      Postnhost::Template.current.update!(name: "workspace-journal")
      category = create(:category, name: "Article Category", slug: "article-category")
      create(:article_category, article: published_article, category:)
      Postnhost::Publishing::Articles::Publish.call(article: published_article)

      get "/#{published_article.slug}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
      expect(response.body).to include("xl:grid-cols-[minmax(0,1fr)_minmax(0,820px)_minmax(0,1fr)]")
      expect(response.body).to include("lg:mx-auto lg:w-full lg:max-w-[820px]")
      expect(response.body).to include("Article Category")
      expect(response.body).to include(published_article.title)
      expect(response.body).not_to include("Share this post")
    end

    it "uses custom OG title, schema headline, and excerpt as meta description when enabled" do
      article = create(
        :article,
        :published,
        og_title: "Custom OG Title",
        schema_headline: "Custom Schema Headline",
        meta_description: "Default Meta Description",
        custom_excerpt: "Custom excerpt built to improve click-through rate on branded traffic.",
        use_excerpt_as_meta_description: true
      )

      get "/#{article.slug}"

      expect(response.body).to include('<meta property="og:title" content="Custom OG Title"')
      expect(response.body).to include('name="description" content="Custom excerpt built to improve click-through rate on branded traffic."')
      expect(response.body).to include('"headline":"Custom Schema Headline"')
      expect(response.body).not_to include('name="description" content="Default Meta Description"')
    end

    it "returns 404 for unpublished article" do
      get "/#{unpublished_article.slug}"
      expect(response).to have_http_status(:not_found)
    end

    it "renders linked multi-author byline and multi-author metadata" do
      first_author = create(:user, name: "Alex Writer", slug: "alex-writer")
      second_author = create(:user, name: "Sam Editor", slug: "sam-editor")
      article = create(:article, :published, user: first_author)
      create(:article_author, article:, user: second_author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article:)

      get "/#{article.slug}"

      expect(response.body).to include("Alex Writer")
      expect(response.body).to include("Sam Editor")
      expect(response.body).to include("/authors/alex-writer")
      expect(response.body).to include("/authors/sam-editor")
      expect(response.body.scan('property="article:author"').length).to eq(2)
      expect(response.body.scan('name="author"').length).to eq(2)
      expect(response.body).to include('"@type":"BlogPosting"')
      expect(response.body).to include("/authors/alex-writer/#person")
      expect(response.body).to include("/authors/sam-editor/#person")
    end

    it "renders author names without author page URLs when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)
      first_author = create(:user, name: "Alex Writer", slug: "alex-writer")
      second_author = create(:user, name: "Sam Editor", slug: "sam-editor")
      article = create(:article, :published, user: first_author)
      create(:article_author, article:, user: second_author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article:)

      get "/#{article.slug}"

      expect(response.body).to include("Alex Writer")
      expect(response.body).to include("Sam Editor")
      expect(response.body).not_to include("/authors/alex-writer")
      expect(response.body).not_to include("/authors/sam-editor")
      expect(response.body).not_to include('property="article:author"')
      expect(response.body.scan('name="author"').length).to eq(2)
      expect(response.body).not_to include("#person")
    end

    it "keeps the published author assignment while the draft changes" do
      old_author = create(:user, name: "Old Author", slug: "old-author")
      new_author = create(:user, name: "New Author", slug: "new-author")
      article = create(:article, :published, user: old_author)
      article.article_authors.destroy_all
      create(:article_author, article:, user: new_author, position: 1)

      get "/#{article.slug}"

      expect(response.body).to include("Old Author")
      expect(response.body).to include("/authors/old-author")
      expect(response.body).not_to include("New Author")
      expect(response.body).not_to include("/authors/new-author")
    end

    it "keeps a removed draft creator in the public snapshot until republish" do
      creator = create(:user, name: "Removed Creator", slug: "removed-creator")
      article = create(:article, :published, user: creator)

      article.article_authors.destroy_all

      get "/#{article.slug}"

      expect(response.body).to include("Removed Creator")
      expect(response.body).to include("/authors/removed-creator")
      expect(response.body).to include('property="article:author"')
      expect(response.body).to include('name="author"')
    end
  end

  describe "GET /:locale" do
    let!(:variant) { create(:article_variant, :published, article: published_article, language:) }

    it "returns http success" do
      get "/#{language.html_lang}"
      expect(response).to have_http_status(:success)
    end

    it "renders localized Top Picks with published variants only" do
      included_article = create(
        :article,
        :published,
        language: default_language,
        title: "Default Pick With Variant",
        top_pick: true
      )
      included_variant = create(
        :article_variant,
        :published,
        article: included_article,
        language: language,
        title: "Localized Top Pick"
      )
      missing_variant_article = create(
        :article,
        :published,
        language: default_language,
        title: "Default Pick Without Variant",
        top_pick: true
      )

      get "/#{language.html_lang}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("postnhost.public.blog.top_picks"))
      expect(response.body).to include(included_variant.title)
      expect(response.body).not_to include(included_article.title)
      expect(response.body).not_to include(missing_variant_article.title)
    end

    it "does not treat arbitrary two-letter paths as locales" do
      get "/ed"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for the blog default language prefix (canonical URLs are unprefixed)" do
      get "/#{default_language.html_lang}"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for default-language article paths with a locale prefix" do
      get "/#{default_language.html_lang}/#{published_article.slug}"

      expect(response).to have_http_status(:not_found)
    end

    it "resolves localized root when request has a mount script_name" do
      get "/#{language.html_lang}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:success)
    end

    it "returns 404 for unknown locale when request has a mount script_name" do
      get "/xx", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for default locale when request has a mount script_name" do
      get "/#{default_language.html_lang}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:not_found)
    end

    context "with pagination" do
      let!(:extra_variants) do
        create_list(:article_variant, 20, :published, language:)
      end

      it "shows first page with up to 15 variants" do
        get "/#{language.html_lang}"
        expect(response).to have_http_status(:success)
        expect(Postnhost::Snapshot::ArticleVariant.where(language:).count).to be > 15
      end

      it "shows second page with remaining variants" do
        get "/#{language.html_lang}?page=2"
        expect(response).to have_http_status(:success)
      end

      it "omits description meta tags on localized paginated pages" do
        get "/#{language.html_lang}?page=2"

        expect(response.body).not_to include('name="description"')
        expect(response.body).not_to include('property="og:description"')
        expect(response.body).not_to include('name="twitter:description"')
      end

      it "redirects localized page=1 to the canonical localized first page URL" do
        get "/#{language.html_lang}?page=1"

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to("/#{language.html_lang}")
      end
    end

    context "with search" do
      it "filters localized published variants by title and content" do
        matching_article = create(:article, :published, language: default_language)
        non_matching_article = create(:article, :published, language: default_language)

        matching_variant = create(
          :article_variant,
          :published,
          article: matching_article,
          language: language,
          title: "Busqueda Localizada",
          content: "<p>needle-localized-content</p>"
        )

        non_matching_variant = create(
          :article_variant,
          :published,
          article: non_matching_article,
          language: language,
          title: "Otro titulo",
          content: "<p>contenido distinto</p>"
        )

        get "/#{language.html_lang}/search?s=needle-localized"

        expect(response).to have_http_status(:success)
        expect(response.body).to include(matching_variant.title)
        expect(response.body).not_to include(non_matching_variant.title)
        expect(response.body).to include('name="robots" content="noindex, nofollow"')
      end

      it "uses localized search endpoint in header trigger" do
        get "/#{language.html_lang}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include("href=\"/#{language.html_lang}/search\"")
      end

      it "returns 404 and hides the localized trigger when search is disabled" do
        Postnhost::Setting.current.update!(search_enabled: false)

        get "/#{language.html_lang}"

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.css("a[href='/#{language.html_lang}/search']")).to be_empty

        get "/#{language.html_lang}/search?s=needle-localized"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Routing Error")
        expect(response.body).to include("Not Found")
      end
    end

    it "falls back article links to default url when localized variant is missing" do
      only_default_article = create(:article, :published, language: default_language, title: "Only Default")
      setting = Postnhost::Setting.current
      setting.update!(use_auto_header_navigation: false)
      setting.current_navigation.replace_tree!(
        locale_key: "en",
        tree: {
          "header" => [
            { "id" => -1, "kind" => "link", "label" => "Only Default", "target_kind" => "article", "target_id" => only_default_article.id, "children" => [] }
          ],
          "footer" => []
        }
      )

      get "/#{language.html_lang}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("href=\"/#{only_default_article.slug}\"")
    end
  end

  describe "GET /:locale/:slug" do
    let!(:variant) { create(:article_variant, :published, article: published_article, language:) }

    it "returns http success for published variant" do
      get "/#{language.html_lang}/#{published_article.slug}"
      expect(response).to have_http_status(:success)
    end

    it "returns 404 when variant is not published" do
      Postnhost::Publishing::ArticleVariants::Unpublish.call(article_variant: variant)
      get "/#{language.html_lang}/#{published_article.slug}"
      expect(response).to have_http_status(:not_found)
    end

    it "uses variant-level OG title and schema headline when present" do
      variant.update!(
        og_title: "Variant OG Title",
        schema_headline: "Variant Schema Headline"
      )
      Postnhost::Publishing::ArticleVariants::Publish.call(article_variant: variant)

      get "/#{language.html_lang}/#{published_article.slug}"

      expect(response.body).to include('<meta property="og:title" content="Variant OG Title"')
      expect(response.body).to include('"headline":"Variant Schema Headline"')
    end

    it "returns success for localized article when request has a mount script_name" do
      get "/#{language.html_lang}/#{published_article.slug}", headers: { "SCRIPT_NAME" => "/blog" }

      expect(response).to have_http_status(:success)
    end

    it "renders localized author links in byline" do
      article = create(:article, :published)
      co_author = create(:user, name: "Co Author", slug: "co-author")
      create(:article_author, article:, user: co_author, position: 2)
      Postnhost::Publishing::Articles::Publish.call(article:)
      create(:article_variant, :published, article:, language:)

      get "/#{language.html_lang}/#{article.slug}"

      expect(response.body).to include("/#{language.html_lang}/authors/#{article.user.slug}")
      expect(response.body).to include("/#{language.html_lang}/authors/co-author")
    end
  end

  describe "GET /preview/:id" do
    let(:user) { create(:user) }

    context "when authenticated" do
      before { sign_in user }

      it "returns http success for any article" do
        get "/preview/#{unpublished_article.id}"
        expect(response).to have_http_status(:success)
      end

      it "renders previews with the workspace-journal template" do
        Postnhost::Template.current.update!(name: "workspace-journal")

        get "/preview/#{unpublished_article.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('class="min-h-dvh overflow-y-scroll bg-white text-[#1f1f1f] antialiased"')
        expect(response.body).to include("xl:grid-cols-[minmax(0,1fr)_minmax(0,820px)_minmax(0,1fr)]")
        expect(response.body).to include("lg:mx-auto lg:w-full lg:max-w-[820px]")
        expect(response.body).to include("Preview Mode")
        expect(response.body).to include("Back to Editor")
      end
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        get "/preview/#{unpublished_article.id}"
        expect(response).to redirect_to(postnhost.new_session_path)
      end
    end
  end
end

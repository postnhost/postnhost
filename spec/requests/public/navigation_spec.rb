require "rails_helper"

RSpec.describe "Public custom navigation", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish_language) { create(:language, :spanish) }
  let!(:article_with_variant) do
    create(:article, :published, language: default_language, title: "Header Article Target")
  end
  let!(:article_fallback) do
    create(:article, :published, language: default_language, title: "Fallback Article Target")
  end
  let!(:category) { create(:category, name: "Navigation Category", slug: "navigation-category") }
  let!(:content_page) { create(:page, :published, title: "Navigation Page", slug: "navigation-page") }

  before do
    create(:article_category, article: article_with_variant, category:)
    Postnhost::Publishing::Articles::Publish.call(article: article_with_variant)
    create(:article_variant, :published, article: article_with_variant, language: spanish_language, title: "Header Article Target ES")
    create(:page_variant, :published, page: content_page, language: spanish_language, title: "Navigation Page ES")
    create(:category_variant, category:, language: spanish_language, name: "Categoria Navegacion")

    Postnhost::Setting.current.update!(
      use_auto_header_navigation: false,
      use_auto_footer_navigation: false
    )
    Postnhost::Setting.current.current_navigation.replace_tree!(
      locale_key: "en",
      tree: custom_navigation_tree
    )
  end

  describe "GET /" do
    it "loads each navigation target type in one batch" do
      queries = capture_sql_queries { get "/" }

      article_target_queries = queries.grep(/postnhost_article_snapshots.*article_id.*IN/)
      page_target_queries = queries.grep(/postnhost_page_snapshots.*page_id/)
      category_target_queries = queries.grep(/postnhost_categories.*postnhost_article_snapshot_categories/)

      expect(response).to have_http_status(:ok)
      expect(article_target_queries.size).to eq(1), article_target_queries.join("\n")
      expect(page_target_queries.size).to eq(1), page_target_queries.join("\n")
      expect(category_target_queries.size).to eq(1), category_target_queries.join("\n")
    end

    it "renders all header target types on the default template" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Header Article EN")
      expect(response.body).to include("href=\"#{postnhost.public_article_path(article_with_variant.slug)}\"")
      expect(response.body).to include("Header Fallback Article EN")
      expect(response.body).to include("href=\"#{postnhost.public_article_path(article_fallback.slug)}\"")
      expect(response.body).to include("Header Page EN")
      expect(response.body).to include("href=\"#{postnhost.public_static_page_path(slug: content_page.slug)}\"")
      expect(response.body).to include("Header Category EN")
      expect(response.body).to include("href=\"#{postnhost.public_category_path(category.slug)}\"")
      expect(response.body).to include("Header Static EN")
      expect(response.body).to include("href=\"#{postnhost.public_static_page_path(slug: 'terms')}\"")
      expect(response.body).to include("Header External EN")
      expect(response.body).to include("href=\"https://example.com/header-en\"")
      expect(response.body).to include('target="_blank"')
      expect(response.body).to include('rel="noopener noreferrer nofollow"')
      expect(response.body).to include("Header Text EN")
      expect(response.body).not_to include(">Header Text EN</a>")
    end

    it "renders header dropdown children in markup" do
      get "/"

      expect(response.body).to include("Header Group EN")
      expect(response.body).to include("Discover EN")
      expect(response.body).to include("Header Group Link EN")
      expect(response.body).not_to include(">Header Group EN</a>")
    end

    it "renders footer columns and omits external footer links" do
      get "/"

      expect(response.body).to include("Footer Column EN")
      expect(response.body).to include("Footer Column Two EN")
      expect(response.body).to include("Footer Article EN")
      expect(response.body).to include("Footer Page EN")
      expect(response.body).to include("Footer Category EN")
      expect(response.body).to include("Footer Static EN")
      expect(response.body).to include("Footer Column Two Link EN")
      expect(response.body).not_to include('href="https://example.com/footer-en"')
    end
  end

  describe "GET / with swiss-editorial template" do
    before { Postnhost::Template.current.update!(name: "swiss-editorial") }

    it "renders the same custom navigation links" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Header Article EN")
      expect(response.body).to include("href=\"#{postnhost.public_article_path(article_with_variant.slug)}\"")
      expect(response.body).to include("Header Group EN")
      expect(response.body).to include("Discover EN")
      expect(response.body).to include("Footer Column EN")
      expect(response.body).to include("group-hover:visible")
      expect(response.body).not_to include("overflow-x-auto lg:flex")
      expect(response.body).to include("flex items-center justify-between gap-4 py-3 lg:grid")
      expect(response.body).to include("shrink-0 items-center justify-end gap-3 lg:justify-self-end")
    end

    it "renders signed-in dashboard links for desktop and mobile navigation" do
      sign_in create(:user)

      get "/"

      dashboard_links = response.parsed_body.css("body > header a[href='#{postnhost.articles_path}']")

      expect(response).to have_http_status(:ok)
      expect(dashboard_links.size).to eq(2)
      expect(dashboard_links.map { |link| link.text.strip }).to all(eq("Dashboard"))
      expect(dashboard_links).to all(satisfy { |link| link["data-turbo-prefetch"] == "false" })
    end
  end

  describe "GET / with workspace-journal template" do
    before { Postnhost::Template.current.update!(name: "workspace-journal") }

    it "renders the same custom navigation links" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Header Article EN")
      expect(response.body).to include("href=\"#{postnhost.public_article_path(article_with_variant.slug)}\"")
      expect(response.body).to include("Header Group EN")
      expect(response.body).to include("Discover EN")
      expect(response.body).to include("Footer Column EN")
      expect(response.body).to include("flex min-w-0 items-center gap-6")
      expect(response.body).to include("transition-transform duration-200 group-hover:rotate-180")
    end
  end

  describe "independent automatic navigation settings" do
    it "uses a custom header with an automatic footer on every public template" do
      Postnhost::Setting.current.update!(
        use_auto_header_navigation: false,
        use_auto_footer_navigation: true
      )

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        header = response.parsed_body.at_css("body > header")
        footer = response.parsed_body.at_css("body > footer")

        aggregate_failures template_name do
          expect(header.text).to include("Header Article EN")
          expect(footer.text).not_to include("Footer Column EN")
          expect(footer.text).to include("Navigation Category")
        end
      end
    end

    it "uses an automatic header with a custom footer on every public template" do
      Postnhost::Setting.current.update!(
        use_auto_header_navigation: true,
        use_auto_footer_navigation: false
      )

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        header = response.parsed_body.at_css("body > header")
        footer = response.parsed_body.at_css("body > footer")

        aggregate_failures template_name do
          expect(header.text).not_to include("Header Article EN")
          expect(footer.text).to include("Footer Column EN")
          expect(footer.text).not_to include("Navigation Category")
        end
      end
    end
  end

  describe "Powered by attribution" do
    it "renders on every public template by default" do
      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('href="https://postnhost.com"')
        expect(response.body).to include("Powered by")
      end
    end

    it "is hidden on every public template when disabled" do
      Postnhost::Setting.current.update!(show_powered_by: false)

      Postnhost::Template::NAMES.each do |template_name|
        Postnhost::Template.current.update!(name: template_name)

        get "/"

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('href="https://postnhost.com"')
        expect(response.body).not_to include("Powered by")
      end
    end
  end

  describe "GET /es" do
    it "uses localized hrefs when variants exist and falls back otherwise" do
      get "/#{spanish_language.html_lang}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("href=\"/#{spanish_language.html_lang}/#{article_with_variant.slug}\"")
      expect(response.body).to include("href=\"/#{article_fallback.slug}\"")
      expect(response.body).to include("href=\"/#{spanish_language.html_lang}/#{content_page.slug}\"")
      expect(response.body).to include("href=\"/#{spanish_language.html_lang}/#{category.slug}\"")
      expect(response.body).to include("href=\"/#{spanish_language.html_lang}/terms\"")
      expect(response.body).to include("Header Group Link EN")
      expect(response.body).to include("href=\"/#{spanish_language.html_lang}/#{article_with_variant.slug}\"")
    end

    it "keeps default-locale labels when spanish labels were not saved" do
      get "/#{spanish_language.html_lang}"

      expect(response.body).to include("Header Article EN")
      expect(response.body).to include("Footer Column EN")
    end

    it "renders spanish labels after they are saved for the locale" do
      navigation = Postnhost::Setting.current.current_navigation
      header_article = navigation.navigation_items.find { |item| item.label_translations["en"] == "Header Article EN" }

      navigation.replace_tree!(
        locale_key: spanish_language.html_lang,
        tree: {
          "header" => [
            {
              "id" => header_article.id,
              "kind" => "link",
              "label" => "Articulo ES",
              "target_kind" => "article",
              "target_id" => article_with_variant.id,
              "children" => []
            }
          ],
          "footer" => []
        }
      )

      get "/#{spanish_language.html_lang}"

      expect(response.body).to include("Articulo ES")
      expect(response.body).not_to include("Header Article EN")
    end
  end

  def custom_navigation_tree
    {
      "header" => [
        {
          "id" => -1,
          "kind" => "dropdown",
          "label" => "Header Group EN",
          "children" => [
            {
              "id" => -2,
              "kind" => "link",
              "label" => "Header Group Link EN",
              "target_kind" => "article",
              "target_id" => article_with_variant.id,
              "children" => []
            },
            {
              "id" => -3,
              "kind" => "link",
              "label" => "Discover EN",
              "target_kind" => "text",
              "children" => []
            }
          ]
        },
        {
          "id" => -4,
          "kind" => "link",
          "label" => "Header Article EN",
          "target_kind" => "article",
          "target_id" => article_with_variant.id,
          "children" => []
        },
        {
          "id" => -5,
          "kind" => "link",
          "label" => "Header Fallback Article EN",
          "target_kind" => "article",
          "target_id" => article_fallback.id,
          "children" => []
        },
        {
          "id" => -6,
          "kind" => "link",
          "label" => "Header Page EN",
          "target_kind" => "page",
          "target_id" => content_page.id,
          "children" => []
        },
        {
          "id" => -7,
          "kind" => "link",
          "label" => "Header Category EN",
          "target_kind" => "category",
          "target_id" => category.id,
          "children" => []
        },
        {
          "id" => -8,
          "kind" => "link",
          "label" => "Header Static EN",
          "target_kind" => "static_page",
          "target_slug" => "terms",
          "children" => []
        },
        {
          "id" => -9,
          "kind" => "link",
          "label" => "Header External EN",
          "target_kind" => "external",
          "url" => "https://example.com/header-en",
          "nofollow" => true,
          "children" => []
        },
        {
          "id" => -10,
          "kind" => "link",
          "label" => "Header Text EN",
          "target_kind" => "text",
          "children" => []
        }
      ],
      "footer" => [
        {
          "id" => -20,
          "kind" => "column",
          "label" => "Footer Column EN",
          "children" => [
            {
              "id" => -21,
              "kind" => "link",
              "label" => "Footer Article EN",
              "target_kind" => "article",
              "target_id" => article_with_variant.id,
              "children" => []
            },
            {
              "id" => -22,
              "kind" => "link",
              "label" => "Footer Page EN",
              "target_kind" => "page",
              "target_id" => content_page.id,
              "children" => []
            },
            {
              "id" => -23,
              "kind" => "link",
              "label" => "Footer Category EN",
              "target_kind" => "category",
              "target_id" => category.id,
              "children" => []
            },
            {
              "id" => -24,
              "kind" => "link",
              "label" => "Footer Static EN",
              "target_kind" => "static_page",
              "target_slug" => "terms",
              "children" => []
            },
            {
              "id" => -25,
              "kind" => "link",
              "label" => "Footer External EN",
              "target_kind" => "external",
              "url" => "https://example.com/footer-en",
              "nofollow" => false,
              "children" => []
            }
          ]
        },
        {
          "id" => -26,
          "kind" => "column",
          "label" => "Footer Column Two EN",
          "children" => [
            {
              "id" => -27,
              "kind" => "link",
              "label" => "Footer Column Two Link EN",
              "target_kind" => "page",
              "target_id" => content_page.id,
              "children" => []
            }
          ]
        }
      ]
    }
  end
end

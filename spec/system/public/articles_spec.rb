require "rails_helper"

RSpec.describe "Public Articles", type: :system do
  let!(:default_language) { create(:language, :default, name: "English", html_lang: "en") }
  let!(:spanish) { create(:language, name: "Spanish", html_lang: "es", default: false) }
  let!(:user) { create(:user, name: "John Doe") }

  describe "index" do
    it "displays empty state when no articles exist" do
      visit postnhost.root_path

      expect(page).to have_text(I18n.t("postnhost.public.blog.no_articles"))
      expect(page).to have_text(I18n.t("postnhost.public.blog.no_articles_description"))
    end

    it "displays list of published articles" do
      articles = create_list(:article, 3, :published, user:, language: default_language)

      visit postnhost.root_path

      expect(page).to have_text(I18n.t("postnhost.public.site.blog_tagline"))
      expect(page).to have_text(I18n.t("postnhost.public.site.blog_subtitle"))

      articles.each do |article|
        expect(page).to have_text(article.title)
      end
    end

    it "displays articles in another language via article variants" do
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "English Article")

      create(:article_variant, :published,
             article:,
             language: spanish,
             title: "Spanish Article",
             content: "<p>Spanish content</p>")

      visit postnhost.localized_root_path(locale: "es")

      expect(page).to have_text("Spanish Article")
      expect(page).to have_no_text("English Article")
    end

    it "renders pagination translation from locale file by default" do
      create_list(:article, 16, :published, user:, language: default_language)
      Postnhost::Settings::I18nOverrides.clear_cache!
      Postnhost::Setting.current.update!(locale_overrides: {})

      visit postnhost.root_path

      expect(page).to have_css("a[aria-label='Next']")
    end

    it "renders pagination translation from overridden setting" do
      create_list(:article, 16, :published, user:, language: default_language)
      Postnhost::Setting.current.update!(locale_overrides: { "en" => { "postnhost.public.pagination.next" => "Continue" } })
      Postnhost::Settings::I18nOverrides.clear_cache!

      visit postnhost.root_path

      expect(page).to have_css("a[aria-label='Continue']")
      expect(page).to have_no_css("a[aria-label='Next']")
    end
  end

  describe "show" do
    it "displays a published article" do
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "Test Article Title",
                       content: "<p>Test article content</p>",
                       meta_description: "Test description")

      visit postnhost.public_article_path(article.slug)

      expect(page).to have_text("Test Article Title")
      expect(page).to have_text("Test article content")
      expect(page).to have_text("John Doe")
      expect(page).to have_text(article.user.position.presence || I18n.t("postnhost.public.blog.author_label"))
      expect(page).to have_text(I18n.t("postnhost.public.blog.back_to_articles"))
    end

    it "renders custom OG title and schema headline for published article page" do
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "System SEO Article",
                       title_tag: "System SEO Meta Title",
                       og_title: "System SEO OG Title",
                       schema_headline: "System SEO Schema Headline")

      visit postnhost.public_article_path(article.slug)

      expect(page.html).to include('<meta property="og:title" content="System SEO OG Title"')
      expect(page.html).to include('"headline":"System SEO Schema Headline"')
    end

    it "shows edit button for authenticated users" do
      article = create(:article, :published, user:, language: default_language, title: "Editable Article")

      sign_in_as(user)
      visit postnhost.public_article_path(article.slug)

      expect(page).to have_link("Edit", href: postnhost.edit_article_path(article))
    end

    it "shows edit button to variant editor on localized variant pages" do
      article = create(:article, :published, user:, language: default_language, title: "English Title")
      create(:article_variant, :published,
             article:,
             language: spanish,
             title: "Spanish Title",
             content: "<p>Spanish content</p>")

      sign_in_as(user)
      visit postnhost.localized_public_article_path(locale: "es", slug: article.slug)

      expect(page).to have_link("Edit")
    end

    it "hides edit button for guests" do
      article = create(:article, :published, user:, language: default_language, title: "Public Article")

      visit postnhost.public_article_path(article.slug)

      expect(page).to have_text("Public Article")
      expect(page).to have_no_link("Edit", href: postnhost.edit_article_path(article))
    end

    it "displays article in another language" do
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "English Title",
                       content: "<p>English content</p>")
      create(:article_variant, :published,
             article:,
             language: spanish,
             title: "Spanish Title",
             content: "<p>Spanish content</p>")

      visit postnhost.localized_public_article_path(locale: "es", slug: article.slug)

      expect(page).to have_text("Spanish Title")
      expect(page).to have_text("Spanish content")
      expect(page).to have_no_text("English Title")

      expect(page).to have_text(I18n.t("postnhost.public.blog.available_in_languages", locale: :es))
      expect(page).to have_text("English")
      expect(page).to have_text("Spanish")
    end

    it "renders variant OG title and schema headline on localized public page" do
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "English SEO Title")
      create(:article_variant, :published,
             article:,
             language: spanish,
             title: "Spanish SEO Title",
             og_title: "Spanish Variant OG Title",
             schema_headline: "Spanish Variant Schema Headline")

      visit postnhost.localized_public_article_path(locale: "es", slug: article.slug)

      expect(page.html).to include('<meta property="og:title" content="Spanish Variant OG Title"')
      expect(page.html).to include('"headline":"Spanish Variant Schema Headline"')
    end

    it "displays specified suggested articles" do
      main_article = create(:article, :published,
                            user:,
                            language: default_language,
                            title: "Main Article")
      suggested_article = create(:article, :published,
                                 user:,
                                 language: default_language,
                                 title: "Suggested Article",
                                 custom_excerpt: "Suggested custom excerpt for better click-through.")

      main_article.suggested_articles << suggested_article
      Postnhost::Publishing::Articles::Publish.call(article: main_article)

      visit postnhost.public_article_path(main_article.slug)

      expect(page).to have_text(I18n.t("postnhost.public.blog.read_more"))
      expect(page).to have_text("Suggested Article")
      expect(page).to have_text("Suggested custom excerpt for better click-through.")
    end

    it "returns 404 for unpublished articles" do
      article = create(:article, user:, language: default_language)

      visit postnhost.public_article_path(article.slug)

      expect(page).to have_text("Not Found")
        .or have_text("404")
        .or have_text("ActiveRecord::RecordNotFound")
        .or have_current_path(postnhost.root_path)
    end
  end
end

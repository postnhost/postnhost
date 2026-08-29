require "rails_helper"

RSpec.describe Postnhost::PublicPagesHelper, type: :helper do
  let(:default_language) { instance_double(Postnhost::Language, name: "English", html_lang: "en", default: true) }
  let(:second_language) { instance_double(Postnhost::Language, name: "Russian", html_lang: "ru", default: false) }
  let(:category) { instance_double(Postnhost::Category, slug: "tech") }

  before do
    helper.extend(Postnhost::CategoryHelper)
    helper.instance_variable_set(:@current_language, default_language)
    allow(helper.request).to receive_messages(original_url: "https://example.com/current", script_name: "")
    allow(helper).to receive(:params).and_return({})
    allow(helper).to receive(:localized_category_name).with(category, default_language).and_return("Tech")
    allow(helper).to receive(:localized_category_meta_description).with(category, default_language).and_return("Tech desc")
  end

  describe "#current_path_without_locale" do
    it "strips locale prefix from current path" do
      allow(helper.request).to receive(:path_info).and_return("/ru/articles")
      allow(helper).to receive(:params).and_return({ locale: "ru" })

      expect(helper.current_path_without_locale).to eq("/articles")
    end

    it "returns same path when no locale prefix exists" do
      allow(helper.request).to receive(:path_info).and_return("/articles")

      expect(helper.current_path_without_locale).to eq("/articles")
    end

    it "does not strip arbitrary two-letter non-locale slugs" do
      allow(helper.request).to receive(:path_info).and_return("/go")
      allow(helper).to receive(:params).and_return({})

      expect(helper.current_path_without_locale).to eq("/go")
    end
  end

  describe "#localized_path" do
    it "returns path without locale for default language" do
      allow(helper.request).to receive(:path_info).and_return("/ru/articles")
      allow(helper).to receive(:params).and_return({ locale: "ru" })

      expect(helper.localized_path(default_language)).to eq("/articles")
    end

    it "prefixes locale for non-default language" do
      allow(helper.request).to receive(:path_info).and_return("/articles")

      expect(helper.localized_path(second_language)).to eq("/ru/articles")
    end

    it "returns '/' when base path becomes empty" do
      allow(helper.request).to receive(:path_info).and_return("/ru")
      allow(helper).to receive(:params).and_return({ locale: "ru" })

      expect(helper.localized_path(default_language)).to eq("/")
    end

    it "keeps mount path prefix before locale" do
      allow(helper.request).to receive_messages(path_info: "/", script_name: "/blog")

      expect(helper.localized_path(second_language)).to eq("/blog/ru")
    end

    it "keeps mount path when switching from localized to default language" do
      allow(helper.request).to receive_messages(path_info: "/ru/articles", script_name: "/blog")
      allow(helper).to receive(:params).and_return({ locale: "ru" })

      expect(helper.localized_path(default_language)).to eq("/blog/articles")
    end
  end

  describe "#language_root_path" do
    it "returns root path for nil language" do
      expect(helper.language_root_path(nil)).to eq("/")
    end

    it "returns root path for default language" do
      expect(helper.language_root_path(default_language)).to eq("/")
    end

    it "returns localized root path for non-default language" do
      expect(helper.language_root_path(second_language)).to eq("/ru")
    end
  end

  describe "#language_category_path" do
    it "returns non-localized category path for nil language" do
      expect(helper.language_category_path("tech", nil)).to eq("/tech")
    end

    it "returns non-localized category path for default language" do
      expect(helper.language_category_path("tech", default_language)).to eq("/tech")
    end

    it "returns localized category path for non-default language" do
      expect(helper.language_category_path("tech", second_language)).to eq("/ru/tech")
    end
  end

  describe "#language_search_url" do
    it "builds search URLs for absent, default, and localized languages" do
      expect(helper.language_search_url(nil)).to eq("http://test.host/search")
      expect(helper.language_search_url(default_language)).to eq("http://test.host/search")
      expect(helper.language_search_url(second_language)).to eq("http://test.host/ru/search")
    end
  end

  describe "#public_page_number" do
    it "parses page number from params" do
      allow(helper).to receive(:params).and_return({ page: "2" })

      expect(helper.public_page_number).to eq(2)
    end

    it "returns 0 when page param is missing" do
      allow(helper).to receive(:params).and_return({})

      expect(helper.public_page_number).to eq(0)
    end
  end

  describe "#paginated_public_page?" do
    it "is true for pages greater than 1" do
      allow(helper).to receive(:params).and_return({ page: "2" })

      expect(helper.paginated_public_page?).to be(true)
    end

    it "is false for first page" do
      allow(helper).to receive(:params).and_return({})

      expect(helper.paginated_public_page?).to be(false)
    end
  end

  describe "#public_blog_index_title" do
    it "returns default blog title for first page" do
      allow(helper).to receive(:params).and_return({})

      expect(helper.public_blog_index_title).to eq(I18n.t("postnhost.public.site.blog_meta_title"))
    end

    it "returns paginated blog title with page number" do
      allow(helper).to receive(:params).and_return({ page: "2" })

      expect(helper.public_blog_index_title).to include("2")
    end
  end

  describe "#public_blog_index_url" do
    it "returns original URL for first page" do
      allow(helper).to receive(:params).and_return({})

      expect(helper.public_blog_index_url).to eq("https://example.com/current")
    end

    it "returns root URL for paginated page" do
      allow(helper).to receive(:params).and_return({ page: "2" })

      expect(helper.public_blog_index_url).to eq("http://test.host/")
    end
  end

  describe "#public_blog_heading" do
    it "returns tagline for first page" do
      allow(helper).to receive(:params).and_return({})

      expect(helper.public_blog_heading).to eq(I18n.t("postnhost.public.site.blog_tagline"))
    end

    it "returns paginated heading for later pages" do
      allow(helper).to receive(:params).and_return({ page: "3" })

      expect(helper.public_blog_heading).to eq(I18n.t("postnhost.public.blog.page_title", page: 3))
    end
  end

  describe "#show_public_blog_subtitle?" do
    it "is true on first page" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.show_public_blog_subtitle?).to be(true)
    end

    it "is false on paginated pages" do
      allow(helper).to receive(:params).and_return({ page: "2" })
      expect(helper.show_public_blog_subtitle?).to be(false)
    end
  end

  describe "#public_category_title" do
    it "returns category title for first page" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.public_category_title(category)).to include("Tech")
    end

    it "returns paginated category title for later pages" do
      allow(helper).to receive(:params).and_return({ page: "2" })
      expect(helper.public_category_title(category)).to include("2")
    end
  end

  describe "#public_category_index_url" do
    it "returns current URL for first page" do
      allow(helper).to receive(:params).and_return({})
      allow(helper.request).to receive(:original_url).and_return("https://example.com/tech")

      expect(helper.public_category_index_url(category)).to eq("https://example.com/tech")
    end

    it "returns canonical category URL for paginated page" do
      allow(helper).to receive(:params).and_return({ page: "2" })

      expect(helper.public_category_index_url(category)).to eq("http://test.host/tech")
    end
  end

  describe "#public_category_heading" do
    it "returns category name for first page" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.public_category_heading(category)).to eq("Tech")
    end

    it "returns paginated heading for later pages" do
      allow(helper).to receive(:params).and_return({ page: "2" })
      expect(helper.public_category_heading(category)).to include("2")
    end
  end

  describe "#public_category_description" do
    it "returns localized category description" do
      expect(helper.public_category_description(category)).to eq("Tech desc")
    end
  end

  describe "#show_public_category_description?" do
    it "is true for first page with description" do
      allow(helper).to receive(:params).and_return({})
      expect(helper.show_public_category_description?(category)).to be(true)
    end

    it "is false for paginated pages" do
      allow(helper).to receive(:params).and_return({ page: "2" })
      expect(helper.show_public_category_description?(category)).to be(false)
    end

    it "is false when description is blank" do
      allow(helper).to receive_messages(params: {}, localized_category_meta_description: "")

      expect(helper.show_public_category_description?(category)).to be(false)
    end
  end

  describe "#public_article_show_page?" do
    it "is true on article show page" do
      allow(helper).to receive_messages(controller_name: "articles", action_name: "show")

      expect(helper.public_article_show_page?).to be(true)
    end

    it "is false on non-article pages" do
      allow(helper).to receive_messages(controller_name: "categories", action_name: "index")

      expect(helper.public_article_show_page?).to be(false)
    end
  end

  describe "#show_article_variant_language_switcher?" do
    before do
      allow(helper).to receive_messages(controller_name: "articles", action_name: "show")
    end

    it "is false when variants are nil" do
      helper.instance_variable_set(:@available_variants, nil)

      expect(helper.show_article_variant_language_switcher?).to be(false)
    end

    it "is true when more than one variant exists" do
      helper.instance_variable_set(:@available_variants, [double, double])
      helper.instance_variable_set(:@article, nil)

      expect(helper.show_article_variant_language_switcher?).to be(true)
    end

    it "is true when article is public and variants exist" do
      helper.instance_variable_set(:@available_variants, [double])
      helper.instance_variable_set(:@article, instance_double(Postnhost::Snapshot::Article))

      expect(helper.show_article_variant_language_switcher?).to be(true)
    end

    it "is false when only one variant and article is not public" do
      helper.instance_variable_set(:@available_variants, [double])
      helper.instance_variable_set(:@article, nil)

      expect(helper.show_article_variant_language_switcher?).to be(false)
    end

    it "supports ActiveRecord-like variant relations" do
      variants = instance_double(ActiveRecord::Relation, exists?: true)
      allow(variants).to receive(:offset).with(1).and_return(instance_double(ActiveRecord::Relation, exists?: false))
      helper.instance_variable_set(:@available_variants, variants)
      helper.instance_variable_set(:@article, instance_double(Postnhost::Snapshot::Article))

      expect(helper.show_article_variant_language_switcher?).to be(true)
    end
  end

  describe "#show_page_variant_language_switcher?" do
    before do
      allow(helper).to receive_messages(controller_name: "static_pages", action_name: "show")
    end

    it "supports array-like variant collections" do
      helper.instance_variable_set(:@available_variants, [double])
      helper.instance_variable_set(:@page, instance_double(Postnhost::Snapshot::Page))

      expect(helper.show_page_variant_language_switcher?).to be(true)
    end

    it "supports ActiveRecord-like variant relations" do
      variants = instance_double(ActiveRecord::Relation, exists?: false)
      allow(variants).to receive(:offset).with(1).and_return(instance_double(ActiveRecord::Relation, exists?: true))
      helper.instance_variable_set(:@available_variants, variants)
      helper.instance_variable_set(:@page, nil)

      expect(helper.show_page_variant_language_switcher?).to be(true)
    end
  end

  describe "#show_other_languages_switcher?" do
    it "is true when there are other languages and not article show page" do
      allow(helper).to receive_messages(controller_name: "categories", action_name: "index")
      helper.instance_variable_set(:@other_languages, [second_language])

      expect(helper.show_other_languages_switcher?).to be(true)
    end

    it "is false on article show page" do
      allow(helper).to receive_messages(controller_name: "articles", action_name: "show")
      helper.instance_variable_set(:@other_languages, [second_language])

      expect(helper.show_other_languages_switcher?).to be(false)
    end
  end

  describe "#localized_language_options" do
    it "returns only current language when variants are blank" do
      helper.instance_variable_set(:@current_language, default_language)
      helper.instance_variable_set(:@available_variants, nil)
      allow(helper).to receive(:localized_path) { |language| "/#{language.html_lang}" }

      primary = instance_double(Postnhost::Snapshot::Article, language: nil)

      expect(helper.localized_language_options(primary)).to eq([["English", "/en"]])
    end

    it "returns unique options for the primary language and variants" do
      primary_language = instance_double(Postnhost::Language, name: "Spanish", html_lang: "es", default: false)
      variant_language = instance_double(Postnhost::Language, name: "Russian", html_lang: "ru", default: false)
      primary = instance_double(Postnhost::Snapshot::Article, language: primary_language)
      variant = instance_double(Postnhost::Snapshot::ArticleVariant, language: variant_language)
      duplicate_variant = instance_double(Postnhost::Snapshot::ArticleVariant, language: variant_language)

      helper.instance_variable_set(:@current_language, default_language)
      helper.instance_variable_set(:@available_variants, [variant, duplicate_variant])
      allow(helper).to receive(:localized_path) { |language| "/#{language.html_lang}" }

      options = helper.localized_language_options(primary)

      expect(options).to include(["English", "/en"], ["Spanish", "/es"], ["Russian", "/ru"])
      expect(options.count { |(_, path)| path == "/ru" }).to eq(1)
    end
  end

  describe "#default_language_options" do
    it "returns base language option when other languages are nil" do
      helper.instance_variable_set(:@current_language, default_language)
      helper.instance_variable_set(:@other_languages, nil)
      allow(helper).to receive(:localized_path) { |language| "/#{language.html_lang}" }

      expect(helper.default_language_options).to eq([["English", "/en"]])
    end

    it "returns current language and other language options" do
      helper.instance_variable_set(:@current_language, default_language)
      helper.instance_variable_set(:@other_languages, [second_language])
      allow(helper).to receive(:localized_path) { |language| "/#{language.html_lang}" }

      expect(helper.default_language_options).to eq([["English", "/en"], ["Russian", "/ru"]])
    end
  end
end

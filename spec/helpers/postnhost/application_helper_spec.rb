require "rails_helper"

RSpec.describe Postnhost::ApplicationHelper, type: :helper do
  before do
    helper.define_singleton_method(:current_setting) { Postnhost::Setting.current }
  end

  describe "#postnhost_openai_api_key_configured?" do
    it "returns false when openai_api_key is blank" do
      allow(Postnhost.config).to receive(:openai_api_key).and_return(nil)

      expect(helper.postnhost_openai_api_key_configured?).to be(false)
    end

    it "returns true when openai_api_key is present" do
      allow(Postnhost.config).to receive(:openai_api_key).and_return("sk-test")

      expect(helper.postnhost_openai_api_key_configured?).to be(true)
    end
  end

  describe "#postnhost_public_locale_file_present_for?" do
    it "accepts a blank locale" do
      expect(helper.postnhost_public_locale_file_present_for?("  ")).to be(true)
    end

    it "returns true when the engine ships the locale file" do
      expect(helper.postnhost_public_locale_file_present_for?("es")).to be(true)
    end

    it "returns true when the host app has the locale file" do
      host_file = Rails.root.join("config/locales/zz-host-only.yml")
      FileUtils.mkdir_p(host_file.dirname)
      File.write(host_file, "zz-host-only:\n  postnhost:\n    public: {}\n")

      expect(helper.postnhost_public_locale_file_present_for?("zz-host-only")).to be(true)
    ensure
      FileUtils.rm_f(host_file)
    end

    it "returns false when neither engine nor host has the file" do
      expect(helper.postnhost_public_locale_file_present_for?("missing-locale-xyz")).to be(false)
    end
  end

  describe "language switcher helpers" do
    let(:default_language) { instance_double(Postnhost::Language, html_lang: "en", default: true) }
    let(:italian_language) { instance_double(Postnhost::Language, html_lang: "it", default: false) }

    before do
      allow(helper).to receive(:params).and_return({})
      allow(helper.request).to receive_messages(path_info: "/articles", script_name: "")
    end

    describe "#current_path_without_locale" do
      it "strips current locale from path when locale param is present" do
        allow(helper).to receive(:params).and_return({ locale: "it" })
        allow(helper.request).to receive(:path_info).and_return("/it/articles")

        expect(helper.current_path_without_locale).to eq("/articles")
      end

      it "keeps two-letter slugs when locale param is not present" do
        allow(helper.request).to receive(:path_info).and_return("/go")

        expect(helper.current_path_without_locale).to eq("/go")
      end
    end

    describe "#localized_path" do
      it "adds locale for non-default language" do
        expect(helper.localized_path(italian_language)).to eq("/it/articles")
      end

      it "keeps mount path before locale" do
        allow(helper.request).to receive_messages(path_info: "/", script_name: "/blog")

        expect(helper.localized_path(italian_language)).to eq("/blog/it")
      end

      it "removes locale and preserves mount path for default language" do
        allow(helper).to receive(:params).and_return({ locale: "it" })
        allow(helper.request).to receive_messages(path_info: "/it/articles", script_name: "/blog")

        expect(helper.localized_path(default_language)).to eq("/blog/articles")
      end
    end
  end

  describe "author helpers" do
    it "reports author pages as enabled by default" do
      expect(helper.author_pages_enabled?).to be(true)
    end

    it "returns nil author URLs when author pages are disabled" do
      Postnhost::Setting.current.update!(author_pages_enabled: false)
      language = create(:language, :default)

      expect(helper.language_author_path("author-slug", language)).to be_nil
      expect(helper.language_author_url("author-slug", language)).to be_nil
    end

    it "returns explicit article_authors without falling back to creator" do
      article = create(:article, :published)
      article.article_authors.destroy_all

      expect(helper.article_authors(article)).to eq([])
    end

    it "builds author cache key from article variant associations" do
      article = create(:article, :published)
      variant_language = create(:language, :spanish)
      variant = create(:article_variant, :published, article:, language: variant_language)

      cache_key = helper.article_authors_cache_key(variant.article_variant_snapshot)

      expect(cache_key).to include("author_pages_enabled", true)
      expect(cache_key).to include(
        [article.user_id, 0, article.article_snapshot.article_snapshot_authors.first.updated_at.to_i, article.user.updated_at.to_i]
      )
    end

    it "reads author identity and avatar attributes" do
      avatar = instance_double(Postnhost::AvatarUploader, url: "https://example.com/avatar.webp")
      author = instance_double(Postnhost::User, name: "Ada Lovelace", avatar_file?: true, avatar_file: avatar)

      expect(helper.author_name(author)).to eq("Ada Lovelace")
      expect(helper.author_initials(author)).to eq("AL")
      expect(helper.author_avatar(author)).to eq("https://example.com/avatar.webp")
    end

    it "normalizes and filters public social links" do
      author = create(:user, website_url: "example.com/profile", x_url: "not a valid host")

      expect(helper.author_social_links(author)).to include(
        hash_including(field: :website_url, url: "https://example.com/profile")
      )
      expect(helper.author_social_links(author).pluck(:field)).not_to include(:x_url)
    end

    it "maps draft variants back to their source article" do
      article = create(:article)
      variant = create(:article_variant, article:)

      expect(helper.article_record_for_author_data(variant)).to eq(article)
    end
  end

  describe "#flash_class" do
    it "maps every supported flash level and unknown levels" do
      expect(helper.flash_class(:notice)).to include("bg-blue-50")
      expect(helper.flash_class(:success)).to include("bg-green-50")
      expect(helper.flash_class(:error)).to include("bg-red-50")
      expect(helper.flash_class(:alert)).to include("bg-yellow-50")
      expect(helper.flash_class(:payment_required)).to eq("hidden")
      expect(helper.flash_class(:unknown)).to include("bg-gray-50")
    end
  end

  describe "blank and unsupported helper inputs" do
    it "returns empty values without querying associations" do
      expect(helper.admin_datetime(nil)).to be_nil
      expect(helper.author_name(Object.new)).to be_nil
      expect(helper.article_authors(nil)).to eq([])
      expect(helper.article_authors_cache_key(Object.new)).to eq([])
      expect(helper.author_social_links(nil)).to eq([])
      expect(helper.article_record_for_author_data(nil)).to be_nil
      expect(helper.article_author_records(Object.new)).to eq([])
    end
  end

  describe "language-aware public paths" do
    let(:default_language) { instance_double(Postnhost::Language, html_lang: "en", default: true) }
    let(:italian_language) { instance_double(Postnhost::Language, html_lang: "it", default: false) }

    before { helper.extend(Postnhost::Engine.routes.url_helpers) }

    it "builds root and category paths for absent, default, and localized languages" do
      expect(helper.language_root_path(nil)).to eq("/")
      expect(helper.language_root_path(default_language)).to eq("/")
      expect(helper.language_root_path(italian_language)).to eq("/it")
      expect(helper.language_category_path("news", nil)).to eq("/news")
      expect(helper.language_category_path("news", default_language)).to eq("/news")
      expect(helper.language_category_path("news", italian_language)).to eq("/it/news")
    end

    it "builds author paths and URLs for absent, default, and localized languages" do
      expect(helper.language_author_path("ada", nil)).to eq("/authors/ada")
      expect(helper.language_author_path("ada", default_language)).to eq("/authors/ada")
      expect(helper.language_author_path("ada", italian_language)).to eq("/it/authors/ada")
      expect(helper.language_author_url("ada", nil)).to eq("http://test.host/authors/ada")
      expect(helper.language_author_url("ada", default_language)).to eq("http://test.host/authors/ada")
      expect(helper.language_author_url("ada", italian_language)).to eq("http://test.host/it/authors/ada")
    end
  end

  describe "#normalize_external_url" do
    it "accepts HTTP hosts and rejects blank, malformed, and unsupported URLs" do
      expect(helper.normalize_external_url("example.com/path")).to eq("https://example.com/path")
      expect(helper.normalize_external_url("https://example.com/path")).to eq("https://example.com/path")
      expect(helper.normalize_external_url(" ")).to be_nil
      expect(helper.normalize_external_url("mailto:editor@example.com")).to be_nil
      expect(helper.normalize_external_url("https://")).to be_nil
    end
  end
end

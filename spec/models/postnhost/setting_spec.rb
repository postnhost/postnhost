require "rails_helper"

RSpec.describe Postnhost::Setting, type: :model do
  around do |example|
    original_timezone = Postnhost.config.default_timezone
    original_site_url = Postnhost.config.site_url
    original_public_page_size = Postnhost.config.public_page_size
    example.run
  ensure
    Postnhost.configure do |config|
      config.default_timezone = original_timezone
      config.site_url = original_site_url
      config.public_page_size = original_public_page_size
    end
  end

  describe "validations" do
    it "allows a valid timezone name" do
      setting = described_class.new(timezone: "Europe/Berlin")

      expect(setting).to be_valid
    end

    it "allows the site URL to remain unconfigured" do
      setting = described_class.new(site_url: nil)

      expect(setting).to be_valid
    end

    it "rejects an unknown timezone name" do
      setting = described_class.new(timezone: "Mars/Olympus")

      expect(setting).not_to be_valid
      expect(setting.errors[:timezone]).to include("is not included in the list")
    end

    it "normalizes a canonical site URL" do
      setting = described_class.new(site_url: " https://example.com/ ")

      expect(setting).to be_valid
      expect(setting.site_url).to eq("https://example.com")
    end

    it "rejects a site URL with a path" do
      setting = described_class.new(site_url: "https://example.com/blog")

      expect(setting).not_to be_valid
      expect(setting.errors[:site_url]).to include("must be an HTTP(S) origin without a path, query, or fragment")
    end

    it "rejects a non-HTTP site URL" do
      setting = described_class.new(site_url: "mailto:editor@example.com")

      expect(setting).not_to be_valid
      expect(setting.errors[:site_url]).to include("must be an HTTP(S) origin without a path, query, or fragment")
    end

    it "requires public page size to be between 1 and 100" do
      setting = described_class.new(public_page_size: 101)

      expect(setting).not_to be_valid
      expect(setting.errors[:public_page_size]).to include("must be in 1..100")
    end

    it "allows public page size to use the initializer default" do
      setting = described_class.new(public_page_size: nil)

      expect(setting).to be_valid
    end

    it "requires a supported site indexing value" do
      setting = described_class.new(site_indexing: "sometimes")

      expect(setting).not_to be_valid
      expect(setting.errors[:site_indexing]).to include("is not included in the list")
    end

    it "requires author_pages_enabled to be boolean" do
      setting = described_class.new(author_pages_enabled: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:author_pages_enabled]).to include("is not included in the list")
    end

    it "requires automatic header navigation to be boolean" do
      setting = described_class.new(use_auto_header_navigation: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:use_auto_header_navigation]).to include("is not included in the list")
    end

    it "requires automatic footer navigation to be boolean" do
      setting = described_class.new(use_auto_footer_navigation: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:use_auto_footer_navigation]).to include("is not included in the list")
    end

    it "requires search_enabled to be boolean" do
      setting = described_class.new(search_enabled: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:search_enabled]).to include("is not included in the list")
    end

    it "requires show_powered_by to be boolean" do
      setting = described_class.new(show_powered_by: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:show_powered_by]).to include("is not included in the list")
    end
  end

  describe "#canonical_url_for" do
    it "replaces the request origin and removes query parameters" do
      setting = described_class.new(site_url: "https://www.example.com")

      expect(setting.canonical_url_for("http://request.example/blog/article?preview=true")).to eq(
        "https://www.example.com/blog/article"
      )
    end

    it "uses the request origin when the site URL is unconfigured" do
      setting = described_class.new(site_url: nil)

      expect(setting.canonical_url_for("https://request.example/blog/article?preview=true#content")).to eq(
        "https://request.example/blog/article"
      )
    end
  end

  describe "#site_url_options" do
    it "returns no overrides when the site URL is unconfigured" do
      setting = described_class.new(site_url: nil)

      expect(setting.site_url_options).to eq({})
    end
  end

  describe "#site_configuration_cache_key" do
    it "includes site indexing" do
      setting = described_class.new(site_url: "https://example.com", public_page_size: 20, site_indexing: "noindex")

      expect(setting.site_configuration_cache_key).to eq(["https://example.com", 20, "noindex"])
    end
  end

  describe "initializer defaults" do
    subject(:setting) { described_class.new(site_url: nil, public_page_size: nil) }

    it "uses initializer values when dashboard values are blank" do
      Postnhost.configure do |config|
        config.site_url = "https://initializer.example.com"
        config.public_page_size = 24
      end

      expect(setting.effective_site_url).to eq("https://initializer.example.com")
      expect(setting.effective_public_page_size).to eq(24)
    end

    it "gives dashboard values priority" do
      setting.site_url = "https://dashboard.example.com"
      setting.public_page_size = 30
      Postnhost.configure do |config|
        config.site_url = "https://initializer.example.com"
        config.public_page_size = 24
      end

      expect(setting.effective_site_url).to eq("https://dashboard.example.com")
      expect(setting.effective_public_page_size).to eq(30)
    end
  end

  describe "#effective_timezone_name" do
    it "returns setting timezone when present" do
      setting = described_class.new(timezone: "Asia/Tokyo")

      expect(setting.effective_timezone_name).to eq("Asia/Tokyo")
    end

    it "falls back to configured default timezone when setting timezone is blank" do
      setting = described_class.new(timezone: nil)

      Postnhost.configure { |config| config.default_timezone = "Europe/Paris" }

      expect(setting.effective_timezone_name).to eq("Europe/Paris")
    end

    it "falls back to UTC when configured timezone is invalid" do
      setting = described_class.new(timezone: nil)

      Postnhost.configure { |config| config.default_timezone = "Invalid/Timezone" }

      expect(setting.effective_timezone_name).to eq("UTC")
    end
  end

  describe "#current_navigation" do
    let!(:default_language) { create(:language, :default) }

    it "returns singleton navigation for setting" do
      setting = described_class.current

      expect { setting.current_navigation }.to change(Postnhost::Navigation, :count).by(1)
      expect(setting.current_navigation).to eq(setting.reload.navigation)
    end
  end
end

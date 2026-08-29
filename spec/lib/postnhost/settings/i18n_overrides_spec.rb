require "rails_helper"

RSpec.describe Postnhost::Settings::I18nOverrides do
  around do |example|
    setting = Postnhost::Setting.current
    original_overrides = setting.locale_overrides.deep_dup
    described_class.clear_cache!

    example.run
  ensure
    setting.update_column(:locale_overrides, original_overrides)
    described_class.clear_cache!
  end

  describe "global I18n patch integration" do
    it "uses locale override instead of locale file value" do
      Postnhost::Setting.current.update_column(:locale_overrides, { "en" => { "postnhost.public.site.schema_site_name" => "postnhost custom" } })
      described_class.clear_cache!

      expect(I18n.t("postnhost.public.site.schema_site_name", locale: :en)).to eq("postnhost custom")
    end

    it "supports interpolation in overridden strings" do
      Postnhost::Setting.current.update_column(:locale_overrides, { "en" => { "postnhost.public.blog.more_in_category" => "More from %<category>s" } })
      described_class.clear_cache!

      expect(I18n.t("postnhost.public.blog.more_in_category", locale: :en, category: "Ruby")).to eq("More from Ruby")
    end

    it "falls back to locale file value when override does not exist" do
      Postnhost::Setting.current.update_column(:locale_overrides, {})
      described_class.clear_cache!

      expect(I18n.t("postnhost.public.pagination.next", locale: :en)).to eq("Next")
    end

    it "does not load settings for translations outside the PostnHost namespace" do
      allow(Postnhost::Setting).to receive(:current).and_call_original

      I18n.t("errors.messages.blank", locale: :en)

      expect(Postnhost::Setting).not_to have_received(:current)
    end
  end

  describe ".locale_keys" do
    it "returns only locales backed by Language records" do
      expect(described_class.locale_keys({}, allowed_locales: %w[de en])).to eq(%w[en de])
    end

    it "returns no locales when the allowed list is empty" do
      expect(described_class.locale_keys({}, allowed_locales: [])).to be_empty
    end
  end
end

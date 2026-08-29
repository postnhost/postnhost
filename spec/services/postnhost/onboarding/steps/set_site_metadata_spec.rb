require "rails_helper"

RSpec.describe Postnhost::Onboarding::Steps::SetSiteMetadata do
  describe ".call" do
    it "stores site copy overrides and advances to sample content" do
      user = create(:user)
      setting = Postnhost::Setting.current
      translations = site_copy_keys.index_with { |key| "Value for #{key}" }
      session = { onboarding_pending_user_id: user.id, onboarding_locale: "en" }
      params = ActionController::Parameters.new(
        step: "3",
        site_url: "https://blog.example.com",
        site_indexing: "noindex",
        translations:
      )

      setting.update!(locale_overrides: {})

      result = described_class.call(params:, session:)

      expect(result).to be_success
      expect(result.status).to eq(:redirect_onboarding)
      expect(session[:onboarding_step]).to eq(4)
      expect(setting.reload.locale_overrides.fetch("en")).to include(translations)
      expect(setting.site_url).to eq("https://blog.example.com")
      expect(setting.site_indexing).to eq("noindex")
    end

    it "returns the submitted site URL when validation fails" do
      user = create(:user)
      session = { onboarding_pending_user_id: user.id, onboarding_locale: "en" }
      params = ActionController::Parameters.new(
        step: "3",
        site_url: "https://blog.example.com/articles",
        site_indexing: "noindex",
        translations: site_copy_keys.index_with { |key| "Value for #{key}" }
      )

      result = described_class.call(params:, session:)

      expect(result).not_to be_success
      expect(result.status).to eq(:render_show)
      expect(result.value).to include(
        step: 3,
        site_url: "https://blog.example.com/articles",
        site_indexing: "noindex"
      )
      expect(result.errors).to include("Site URL must be an HTTP(S) origin without a path, query, or fragment")
      expect(session[:onboarding_step]).to be_nil
    end
  end

  def site_copy_keys
    Postnhost::Onboarding::Steps::Base::SITE_COPY_KEYS
  end
end

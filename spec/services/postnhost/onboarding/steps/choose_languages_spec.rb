require "rails_helper"

RSpec.describe Postnhost::Onboarding::Steps::ChooseLanguages do
  describe ".call" do
    it "replaces languages and advances to site copy" do
      user = create(:user)
      Postnhost::Language.delete_all
      session = { onboarding_pending_user_id: user.id }
      params = ActionController::Parameters.new(step: "2", language_locales: %w[en fr], default_locale: "en")

      result = described_class.call(params:, session:)

      expect(result).to be_success
      expect(result.status).to eq(:redirect_onboarding)
      expect(Postnhost::Language.count).to eq(2)
      expect(Postnhost::Language.blog_default&.html_lang).to eq("en")
      expect(Postnhost::Language.exists?(html_lang: "fr")).to be(true)
      expect(session[:onboarding_locale]).to eq("en")
      expect(session[:onboarding_language_locales]).to eq(%w[en fr])
      expect(session[:onboarding_step]).to eq(3)
    end
  end
end

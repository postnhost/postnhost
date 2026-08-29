require "rails_helper"

RSpec.describe Postnhost::Onboarding::Steps::FinishSetup do
  describe ".call" do
    it "seeds sample content when requested and returns the user for sign-in" do
      user = create(:user)
      session = {
        onboarding_pending_user_id: user.id,
        onboarding_step: 4,
        onboarding_locale: "en",
        onboarding_language_locales: %w[en]
      }
      params = ActionController::Parameters.new(step: "4", generate_sample: "1")

      allow(Postnhost::SampleData).to receive(:seed!)

      result = described_class.call(params:, session:)

      expect(result).to be_success
      expect(result.status).to eq(:finish_setup)
      expect(result.value).to eq({ user: })
      expect(Postnhost::SampleData).to have_received(:seed!).with(user:)
      expect(session).not_to have_key(:onboarding_pending_user_id)
      expect(session).not_to have_key(:onboarding_step)
      expect(session).not_to have_key(:onboarding_locale)
      expect(session).not_to have_key(:onboarding_language_locales)
    end
  end
end

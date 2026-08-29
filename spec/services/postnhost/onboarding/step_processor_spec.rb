require "rails_helper"

RSpec.describe Postnhost::Onboarding::StepProcessor do
  describe ".call" do
    it "returns a redirect result for an invalid step" do
      result = described_class.call(params: ActionController::Parameters.new(step: "invalid"), session: {})

      expect(result).to be_success
      expect(result.status).to eq(:redirect_onboarding)
      expect(result.value).to eq({ alert: "Invalid step." })
    end

    it "creates the pending admin user and advances to language selection" do
      Postnhost::User.delete_all
      session = {}
      params = ActionController::Parameters.new(
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "admin@example.com",
          password: "secret12"
        }
      )

      result = described_class.call(params:, session:)

      expect(result).to be_success
      expect(result.status).to eq(:redirect_onboarding)
      expect(Postnhost::User.find_by(email: "admin@example.com")).to be_present
      expect(session[:onboarding_pending_user_id]).to be_present
      expect(session[:onboarding_step]).to eq(2)
    end

    it "returns render payload when the default language is not selected" do
      user = create(:user)
      session = { onboarding_pending_user_id: user.id }
      params = ActionController::Parameters.new(step: "2", language_locales: %w[en], default_locale: "fr")

      result = described_class.call(params:, session:)

      expect(result).not_to be_success
      expect(result.status).to eq(:render_show)
      expect(result.errors).to eq(["Default language must be one of the selected languages."])
      expect(result.value).to include(
        step: 2,
        selected_language_locales: %w[en],
        selected_default_locale: "fr"
      )
    end

    it "seeds sample content when requested and returns the user for controller sign-in" do
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

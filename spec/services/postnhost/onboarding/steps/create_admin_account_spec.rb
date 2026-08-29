require "rails_helper"

RSpec.describe Postnhost::Onboarding::Steps::CreateAdminAccount do
  describe ".call" do
    it "creates the pending admin user and advances the session" do
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
  end
end

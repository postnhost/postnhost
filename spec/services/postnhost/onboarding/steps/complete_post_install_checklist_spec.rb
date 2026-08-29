require "rails_helper"

RSpec.describe Postnhost::Onboarding::Steps::CompletePostInstallChecklist do
  describe ".call" do
    it "clears the checklist flag and redirects to articles" do
      session = { onboarding_post_install_checklist: true }
      params = ActionController::Parameters.new(step: "post_install_done")

      result = described_class.call(params:, session:)

      expect(result).to be_success
      expect(result.status).to eq(:redirect_articles)
      expect(session).not_to have_key(:onboarding_post_install_checklist)
    end
  end
end

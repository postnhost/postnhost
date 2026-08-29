require "rails_helper"

RSpec.describe "Public onboarding redirect", type: :request do
  let!(:default_language) { create(:language, :default) }

  describe "GET /" do
    it "redirects to onboarding when no PostnHost users exist" do
      Postnhost::User.delete_all

      get "/"

      expect(response).to redirect_to(postnhost.onboarding_path)
    end

    it "renders the public blog when a PostnHost user exists" do
      create(:user)

      get "/"

      expect(response).to have_http_status(:ok)
    end
  end
end

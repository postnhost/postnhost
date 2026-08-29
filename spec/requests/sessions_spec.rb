require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:default_language) { create(:language, :default) }

  describe "GET /session/new" do
    it "returns ok when a user exists" do
      create(:user)

      get postnhost.new_session_path

      expect(response).to have_http_status(:ok)
    end

    it "redirects to onboarding when no users exist" do
      Postnhost::User.delete_all

      get postnhost.new_session_path

      expect(response).to redirect_to(postnhost.onboarding_path)
    end
  end

  describe "POST /session" do
    it "redirects to onboarding when no users exist" do
      Postnhost::User.delete_all

      post postnhost.session_path, params: { user: { email: "any@example.com", password: "secret12" } }

      expect(response).to redirect_to(postnhost.onboarding_path)
    end

    it "redirects to articles for valid credentials" do
      user = create(:user, password: "password", password_confirmation: "password")

      post postnhost.session_path, params: { user: { email: user.email, password: "password" } }

      expect(response).to redirect_to(postnhost.articles_path)
    end

    it "returns unprocessable content for invalid credentials" do
      user = create(:user, password: "password", password_confirmation: "password")

      post postnhost.session_path, params: { user: { email: user.email, password: "wrong" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /session" do
    it "signs out and redirects to root" do
      user = create(:user)
      sign_in(user)

      delete postnhost.session_path

      expect(response).to redirect_to(postnhost.root_path)
    end
  end
end

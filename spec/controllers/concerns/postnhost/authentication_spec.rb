require "rails_helper"

RSpec.describe Postnhost::Authentication, type: :controller do
  concern_module = described_class

  controller(ApplicationController) do
    include concern_module

    def protected_index
      authenticate_user!
      return if performed?

      render plain: "ok"
    end

    def guest_only
      skip_authentication
      return if performed?

      render plain: "ok"
    end
  end

  before do
    request.host = "example.com"
    routes.draw do
      get "protected_index" => "anonymous#protected_index"
      get "guest_only" => "anonymous#guest_only"
    end
  end

  describe "#authenticate_user!" do
    it "redirects unauthenticated users to onboarding when no user exists" do
      Postnhost::User.delete_all

      get :protected_index

      expect(response).to redirect_to("/onboarding")
    end

    it "redirects unauthenticated users to sign in when users exist" do
      Postnhost::User.create!(
        email: "auth-user@example.com",
        name: "Auth User",
        password: "password",
        password_confirmation: "password"
      )

      get :protected_index

      expect(response).to redirect_to("/session/new")
    end

    it "allows authenticated users" do
      user = Postnhost::User.create!(
        email: "signed-in@example.com",
        name: "Signed In User",
        password: "password",
        password_confirmation: "password"
      )
      session[:user_id] = user.id

      get :protected_index

      expect(response).to have_http_status(:ok)
    end

    it "signs out stale sessions when user is missing" do
      user = Postnhost::User.create!(
        email: "stale-session-auth@example.com",
        name: "Stale Session Auth User",
        password: "password",
        password_confirmation: "password"
      )
      session[:user_id] = user.id
      user.destroy!

      get :protected_index

      expect(response).to redirect_to("/onboarding")
      expect(session[:user_id]).to be_nil
    end
  end

  describe "#skip_authentication" do
    it "redirects signed in users to articles page" do
      user = Postnhost::User.create!(
        email: "skip-auth@example.com",
        name: "Skip Auth User",
        password: "password",
        password_confirmation: "password"
      )
      session[:user_id] = user.id

      get :guest_only

      expect(response).to redirect_to("/articles")
    end

    it "allows guests" do
      get :guest_only

      expect(response).to have_http_status(:ok)
    end

    it "treats stale sessions as guests" do
      user = Postnhost::User.create!(
        email: "stale-session-guest@example.com",
        name: "Stale Session Guest User",
        password: "password",
        password_confirmation: "password"
      )
      session[:user_id] = user.id
      user.destroy!

      get :guest_only

      expect(response).to have_http_status(:ok)
      expect(session[:user_id]).to be_nil
    end
  end
end

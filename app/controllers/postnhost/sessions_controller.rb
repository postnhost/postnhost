module Postnhost
  class SessionsController < ApplicationController
    before_action :redirect_to_onboarding_when_needed, only: %i[new create]
    before_action :skip_authentication, only: %i[new create]

    def new; end

    def create
      user = Postnhost::User.find_by(email: session_params[:email].to_s.downcase.strip)

      if user&.authenticate(session_params[:password].to_s)
        sign_in(user)
        redirect_to articles_path
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      sign_out
      redirect_to root_path
    end

    private

    def redirect_to_onboarding_when_needed
      return if user_signed_in?

      redirect_to postnhost.onboarding_path if Postnhost::User.none? || session[:onboarding_pending_user_id].present?
    end

    def session_params
      params.require(:user).permit(:email, :password)
    end
  end
end

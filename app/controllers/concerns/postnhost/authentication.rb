module Postnhost
  module Authentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_user, :user_signed_in?
    end

    protected

    def authenticate_user!
      return if user_signed_in?

      if Postnhost::User.none?
        redirect_to postnhost.onboarding_path
      else
        redirect_to postnhost.new_session_path, alert: "You need to sign in before continuing."
      end
    end

    def skip_authentication
      return unless user_signed_in?

      redirect_to postnhost.articles_path
    end

    def sign_in(user)
      reset_session
      session[:user_id] = user.id
      cookies.encrypted[:auth_user_id] = {
        value: user.id,
        httponly: true,
        same_site: :lax
      }
    end

    def sign_out
      cookies.delete(:auth_user_id)
      reset_session
    end

    private

    def current_user
      return @current_user if defined?(@current_user)

      user_id = session[:user_id]
      return @current_user = nil if user_id.blank?

      @current_user = Postnhost::User.find_by(id: user_id)
      sign_out if session[:user_id].present? && @current_user.nil?
      @current_user
    end

    def user_signed_in?
      current_user.present?
    end
  end
end

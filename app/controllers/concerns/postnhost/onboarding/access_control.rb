module Postnhost
  module Onboarding
    module AccessControl
      extend ActiveSupport::Concern

      private

      def ensure_onboarding_allowed!
        if user_signed_in?
          return if post_install_checklist_mode?

          redirect_to postnhost.articles_path
          return
        end

        return unless Postnhost::User.exists? && session[:onboarding_pending_user_id].blank?

        redirect_to postnhost.new_session_path, alert: "Sign in to continue."
      end

      def current_step
        step = (session[:onboarding_step] || 1).to_i
        step.clamp(1, 4)
      end

      def pending_user
        id = session[:onboarding_pending_user_id]
        return if id.blank?

        Postnhost::User.find_by(id: id)
      end

      def reset_onboarding_session!
        session.delete(:onboarding_pending_user_id)
        session.delete(:onboarding_step)
        session.delete(:onboarding_locale)
      end

      def post_install_checklist_mode?
        params[:post_install].to_s == "1" && session[:onboarding_post_install_checklist] == true
      end

      def synchronize_onboarding_session
        if session[:onboarding_pending_user_id].present? &&
           !Postnhost::User.exists?(id: session[:onboarding_pending_user_id])
          reset_onboarding_session!
          redirect_to postnhost.onboarding_path, alert: "Setup session expired. Start again."
          return
        end

        return unless Postnhost::User.none? && session[:onboarding_step].to_i > 1

        session[:onboarding_step] = 1
      end
    end
  end
end

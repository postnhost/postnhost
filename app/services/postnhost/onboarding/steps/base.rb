module Postnhost
  module Onboarding
    module Steps
      class Base < BaseService
        SITE_COPY_KEYS = Postnhost::Onboarding::StepAssignment::SITE_COPY_KEYS
        LANGUAGE_OPTIONS = Postnhost::Onboarding::StepAssignment::LANGUAGE_OPTIONS

        attr_reader :params, :session

        def initialize(params:, session:)
          @params = params
          @session = session
        end

        private

        def render_show(**payload)
          alert = payload.delete(:alert)

          ServiceResult.new(
            value: payload.merge(alert:).compact,
            errors: [alert].compact,
            status: :render_show
          )
        end

        def redirect_onboarding(alert: nil)
          success({ alert: }.compact, status: :redirect_onboarding)
        end

        def restart_at_admin_account
          session[:onboarding_step] = 1
          redirect_onboarding(alert: "Continue from step 1.")
        end

        def pending_user
          id = session[:onboarding_pending_user_id]
          return if id.blank?

          Postnhost::User.find_by(id:)
        end

        def reset_onboarding_session!
          session.delete(:onboarding_pending_user_id)
          session.delete(:onboarding_step)
          session.delete(:onboarding_locale)
          session.delete(:onboarding_language_locales)
        end
      end
    end
  end
end

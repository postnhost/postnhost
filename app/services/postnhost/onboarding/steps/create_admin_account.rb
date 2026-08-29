module Postnhost
  module Onboarding
    module Steps
      class CreateAdminAccount < Base
        def call
          user = Postnhost::User.new(admin_user_params)

          return success({ alert: "An account already exists." }, status: :redirect_new_session) unless Postnhost::User.none?

          if user.save
            session[:onboarding_pending_user_id] = user.id
            session[:onboarding_step] = 2
            redirect_onboarding
          else
            render_show(step: 1, user:)
          end
        end

        private

        def admin_user_params
          raw = params[:postnhost_user].presence || params[:user].presence || ActionController::Parameters.new
          raw.permit(:name, :email, :password)
        end
      end
    end
  end
end

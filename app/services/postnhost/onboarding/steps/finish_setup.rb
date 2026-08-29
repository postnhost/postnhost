module Postnhost
  module Onboarding
    module Steps
      class FinishSetup < Base
        def call
          user = pending_user

          unless user
            reset_onboarding_session!
            return redirect_onboarding(alert: "Continue setup from the beginning.")
          end

          Postnhost::SampleData.seed!(user:) if generate_sample?

          reset_onboarding_session!
          success({ user: }, status: :finish_setup)
        end

        private

        def generate_sample?
          %w[1 true yes on].include?(params[:generate_sample].to_s.downcase)
        end
      end
    end
  end
end

module Postnhost
  module Onboarding
    module Steps
      class CompletePostInstallChecklist < Base
        def call
          session.delete(:onboarding_post_install_checklist)
          success(status: :redirect_articles)
        end
      end
    end
  end
end

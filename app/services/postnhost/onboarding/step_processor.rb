module Postnhost
  module Onboarding
    class StepProcessor < BaseService
      STEP_SERVICES = {
        "1" => Steps::CreateAdminAccount,
        "2" => Steps::ChooseLanguages,
        "3" => Steps::SetSiteMetadata,
        "4" => Steps::FinishSetup,
        "post_install_done" => Steps::CompletePostInstallChecklist
      }.freeze

      attr_reader :params, :session

      def initialize(params:, session:)
        @params = params
        @session = session
      end

      def call
        service_class = STEP_SERVICES[params[:step].to_s]
        return success({ alert: "Invalid step." }, status: :redirect_onboarding) unless service_class

        service_class.call(params:, session:)
      end
    end
  end
end

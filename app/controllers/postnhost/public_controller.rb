module Postnhost
  class PublicController < ApplicationController
    before_action :validate_public_locale
    before_action :redirect_to_onboarding_without_users

    private

    def current_setting
      public_request_context.setting
    end

    def public_route_resolution(kind:, slug:)
      resolution = public_request_context.resolve(slug)
      raise ActiveRecord::RecordNotFound unless resolution&.kind == kind

      resolution
    end

    def raise_not_found
      raise ActionController::RoutingError, "Not Found"
    end

    def validate_public_locale
      language = public_request_context.requested_language
      raise_not_found if params[:locale].present? && (language.blank? || language.default?)
    end

    def redirect_to_onboarding_without_users
      redirect_to postnhost.onboarding_path unless Postnhost::User.exists?
    end
  end
end

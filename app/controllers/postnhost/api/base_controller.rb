module Postnhost
  module Api
    # Bearer-only boundary intentionally excludes host session callbacks.
    # rubocop:disable-next Rails/ApplicationController
    class BaseController < ActionController::Base
      skip_forgery_protection
      before_action :prevent_caching
      before_action :authenticate_token!

      private

      attr_reader :api_user

      def authenticate_token!
        scheme, secret = request.authorization.to_s.split(" ", 2)
        token = ApiToken.authenticate(secret) if scheme&.casecmp?("Bearer")
        @api_user = token&.user
        return if api_user

        response.set_header("WWW-Authenticate", 'Bearer realm="PostnHost"')
        render json: { errors: ["A valid bearer token is required"] }, status: :unauthorized
      end

      def prevent_caching
        response.set_header("Cache-Control", "no-store")
      end
    end
  end
end

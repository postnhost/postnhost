module Postnhost
  class ApiTokensController < ApplicationController
    before_action :authenticate_user!
    before_action :prevent_caching
    layout "postnhost/product"

    def index
      @api_tokens = current_user.api_tokens.order(created_at: :desc)
    end

    def create
      @api_token, @secret = ApiToken.issue!(user: current_user, **token_params.to_h.symbolize_keys)
      @api_tokens = current_user.api_tokens.order(created_at: :desc)
      render :index
    rescue ActiveRecord::RecordInvalid => e
      redirect_to api_tokens_path, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      current_user.api_tokens.find(params[:id]).revoke!
      redirect_to api_tokens_path, notice: "API token revoked."
    end

    private

    def prevent_caching
      response.set_header("Cache-Control", "no-store")
    end

    def token_params
      params.require(:api_token).permit(:name)
    end
  end
end

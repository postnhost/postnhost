module Postnhost
  class Articles::CoverImagesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_article, only: %i[create destroy]

    def create
      file = params[:file]

      if file.present?
        @article.cover_image = file

        if @article.save
          render json: { url: @article.cover_image.url }, status: :ok
        else
          render json: { error: @article.errors.full_messages.join(", ") }, status: :unprocessable_content
        end
      else
        render json: { error: "No file provided" }, status: :bad_request
      end
    end

    def destroy
      # HACK: to bypass carrierwave image removal from bucket to keep the version history
      @article.update_column(:cover_image, nil)

      head :no_content
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:article_id])
    end
  end
end

module Postnhost
  class Articles::ImagesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_article

    def create
      file = params[:file]

      if file.present?
        result = @article.upload_inline_image(file)

        if result[:success]
          render json: { url: result[:url] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_content
        end
      else
        render json: { error: "No file provided" }, status: :bad_request
      end
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:article_id])
    end
  end
end

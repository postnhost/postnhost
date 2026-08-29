module Postnhost
  class Articles::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_article

    def new; end

    def create
      language_ids = params[:language_ids] || []

      language_ids.each do |language_id|
        Postnhost::Translation::ArticleVariantJob.perform_later(@article.id, language_id.to_i)

        @article.article_variants.create!(language: Postnhost::Language.find_by(id: language_id.to_i), generating: true)
      end

      redirect_to article_variants_path(@article)
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:article_id])
    end
  end
end

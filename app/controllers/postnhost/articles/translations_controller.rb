module Postnhost
  class Articles::TranslationsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_article

    def new; end

    def create
      result = Postnhost::Translation::Enqueue.call(record: @article, language_ids: Array(params[:language_ids]).map(&:to_i).uniq)
      redirect_to article_variants_path(@article), **(result.success? ? {} : { alert: result.errors.to_sentence })
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:article_id])
    end
  end
end

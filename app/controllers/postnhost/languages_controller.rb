module Postnhost
  class LanguagesController < ApplicationController
    PAGE_SIZE = 15

    before_action :authenticate_user!
    before_action :load_language, only: %i[show edit update destroy]
    layout "postnhost/product"

    def index
      @languages = Postnhost::Language.order(updated_at: :desc)
    end

    def show
      articles = @language.articles.includes(:article_snapshot, :categories).order(created_at: :desc)
      article_variants = @language.article_variants.includes(:article).order(created_at: :desc)

      @articles_pagy, @articles = pagy(:offset, articles, limit: PAGE_SIZE, page_key: "articles_page")
      @article_variants_pagy, @article_variants = pagy(
        :offset,
        article_variants,
        limit: PAGE_SIZE,
        page_key: "article_variants_page"
      )
    end

    def new
      @language = Postnhost::Language.new
    end

    def edit; end

    def create
      @language = Postnhost::Language.new
      @language.assign_attributes(language_params)

      if @language.save
        redirect_to @language
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @language.update(language_params)
        redirect_to languages_url, notice: "Language was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @language.destroy
      redirect_to languages_url, notice: "Language was successfully deleted."
    end

    private

    def load_language
      @language = Postnhost::Language.find(params[:id])
    end

    def language_params
      params.require(:language).permit(:name, :html_lang, :default)
    end
  end
end

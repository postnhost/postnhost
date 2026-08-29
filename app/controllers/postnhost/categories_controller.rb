module Postnhost
  class CategoriesController < ApplicationController
    PAGE_SIZE = 15

    before_action :authenticate_user!
    before_action :load_category, only: %i[show edit update destroy]

    layout "postnhost/product"

    def index
      @categories = Postnhost::Category.order(updated_at: :desc)
    end

    def show
      articles = @category.articles.includes(:article_snapshot, :language).order(created_at: :desc)
      @pagy, @articles = pagy(:offset, articles, limit: PAGE_SIZE)
    end

    def new
      @category = Postnhost::Category.new
    end

    def edit; end

    def create
      @category = Postnhost::Category.new
      @category.assign_attributes(category_params)

      if @category.save
        redirect_to categories_url
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @category.update(category_params)
        redirect_to @category, notice: "Category was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @category.destroy
      redirect_to categories_url, notice: "Category was successfully deleted."
    end

    private

    def load_category
      @category = Postnhost::Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :slug, :meta_description)
    end
  end
end

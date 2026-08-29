module Postnhost
  class CategoryVariantsController < ApplicationController
    before_action :authenticate_user!
    before_action :load_category
    before_action :load_category_variant, only: %i[edit update destroy]
    before_action :ensure_variant_editable, only: %i[edit update]

    layout "postnhost/product"

    def index
      @variants = @category.category_variants.includes(:language).order(:created_at)
      @available_languages = Postnhost::Language.where.not(id: @category.category_variants.select(:language_id))

      default_language = Postnhost::Language.blog_default
      @available_languages = @available_languages.where.not(id: default_language.id) if default_language.present?
    end

    def new
      @category_variant = @category.category_variants.new
      @category_variant.language = Postnhost::Language.find_by(id: params[:language_id]) if params[:language_id]
    end

    def edit; end

    def create
      @category_variant = @category.category_variants.new(variant_params)

      if @category_variant.save
        redirect_to category_variants_path(@category), notice: "Translation was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @category_variant.update(variant_params)
        redirect_to category_variants_path(@category), notice: "Translation was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @category_variant.destroy
      redirect_to category_variants_path(@category), notice: "Translation was successfully deleted."
    end

    private

    def load_category
      @category = Postnhost::Category.find(params[:category_id])
    end

    def load_category_variant
      @category_variant = @category.category_variants.find(params[:id])
    end

    def ensure_variant_editable
      return unless @category_variant.generating?

      redirect_to category_variants_path(@category),
                  alert: "This translation is still in progress. You can edit it when it finishes."
    end

    def variant_params
      params.require(:category_variant).permit(:name, :meta_description, :language_id)
    end
  end
end

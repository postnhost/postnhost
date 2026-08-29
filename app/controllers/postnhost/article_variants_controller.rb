module Postnhost
  class ArticleVariantsController < ApplicationController
    PAGE_SIZE = 15

    before_action :authenticate_user!
    before_action :load_article
    before_action :load_article_variant, only: %i[edit update publish unpublish destroy]
    before_action :ensure_variant_editable, only: %i[edit update publish unpublish]

    layout :resolve_layout

    def index
      variants = @article.article_variants.includes(:language, :article_variant_snapshot).order(:created_at)
      @pagy, @variants = pagy(:offset, variants, limit: PAGE_SIZE)
      @available_languages = Postnhost::Language.where.not(id: @article.article_variants.select(:language_id))
      @available_languages = @available_languages.where.not(id: @article.language_id) if @article.language_id.present?
    end

    def new
      @article_variant = @article.article_variants.new
      @article_variant.language = Postnhost::Language.find_by(id: params[:language_id]) if params[:language_id]
      @article_variant.title = @article.title
      @article_variant.title_tag = @article.title_tag
      @article_variant.og_title = @article.og_title
      @article_variant.schema_headline = @article.schema_headline
      @article_variant.meta_description = @article.meta_description
      @article_variant.custom_excerpt = @article.custom_excerpt
      @article_variant.use_excerpt_as_meta_description = @article.use_excerpt_as_meta_description
      @article_variant.content = @article.content
      @article_variant.save!

      redirect_to edit_article_variant_path(@article, @article_variant)
    end

    def edit; end

    def update
      if @article_variant.update(variant_params)
        respond_to do |format|
          format.html do
            redirect_to edit_article_variant_path(@article, @article_variant)
          end
          format.json { head :no_content }
          format.turbo_stream
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    def publish
      result = Postnhost::Publishing::ArticleVariants::Publish.call(article_variant: @article_variant)
      @article_variant.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html do
          redirect_to edit_article_variant_path(@article, @article_variant), **(error.present? ? { alert: error } : {})
        end
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :publish, status: result.status
        end
      end
    end

    def unpublish
      result = Postnhost::Publishing::ArticleVariants::Unpublish.call(article_variant: @article_variant)
      @article_variant.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html do
          redirect_to edit_article_variant_path(@article, @article_variant), **(error.present? ? { alert: error } : {})
        end
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :unpublish, status: result.status
        end
      end
    end

    def destroy
      @article_variant.destroy
      redirect_to article_variants_path(@article)
    end

    def bulk_publish
      result = Postnhost::Publishing::ArticleVariants::PublishMany.call(article: @article, ids: params[:ids])
      error = result.errors.to_sentence unless result.success?
      error = "#{result.value[:failures].count} translation(s) failed." if result.success? && result.value[:failures].any?

      redirect_to article_variants_path(@article), **(error.present? ? { alert: error } : {})
    end

    def bulk_unpublish
      result = Postnhost::Publishing::ArticleVariants::UnpublishMany.call(article: @article, ids: params[:ids])
      error = result.errors.to_sentence unless result.success?
      error = "#{result.value[:failures].count} translation(s) failed." if result.success? && result.value[:failures].any?

      redirect_to article_variants_path(@article), **(error.present? ? { alert: error } : {})
    end

    def bulk_destroy
      variants = @article.article_variants.where(id: params[:ids]).where.not(generating: true)
      count = variants.count
      variants.destroy_all

      redirect_to article_variants_path(@article), notice: "#{count} translation(s) deleted successfully."
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:article_id])
    end

    def load_article_variant
      @article_variant = @article.article_variants.find(params[:id])
    end

    def ensure_variant_editable
      return unless @article_variant.generating?

      redirect_to article_variants_path(@article),
                  alert: "This translation is still in progress. You can edit it when it finishes."
    end

    def variant_params
      params.require(:article_variant).permit(:title, :title_tag, :og_title, :schema_headline, :meta_description,
                                              :custom_excerpt, :use_excerpt_as_meta_description, :content, :language_id)
    end

    def resolve_layout
      action_name == "index" ? "postnhost/product" : "postnhost/articles"
    end
  end
end

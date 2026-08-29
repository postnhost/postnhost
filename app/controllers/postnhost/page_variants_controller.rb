module Postnhost
  class PageVariantsController < ApplicationController
    PAGE_SIZE = 15

    before_action :authenticate_user!
    before_action :load_page
    before_action :load_page_variant, only: %i[edit update publish unpublish destroy]
    before_action :ensure_variant_editable, only: %i[edit update publish unpublish]

    layout :resolve_layout

    def index
      variants = @page.page_variants.includes(:language, :page_variant_snapshot).order(:created_at)
      @pagy, @variants = pagy(:offset, variants, limit: PAGE_SIZE)
      @available_languages = Postnhost::Language.where.not(id: @page.page_variants.select(:language_id))
      @available_languages = @available_languages.where.not(id: @page.language_id) if @page.language_id.present?
    end

    def new
      @page_variant = @page.page_variants.new
      @page_variant.language = Postnhost::Language.find_by(id: params[:language_id]) if params[:language_id]
      @page_variant.title = @page.title
      @page_variant.title_tag = @page.title_tag
      @page_variant.og_title = @page.og_title
      @page_variant.meta_description = @page.meta_description
      @page_variant.content = @page.content
      @page_variant.save!

      redirect_to edit_page_variant_path(@page, @page_variant),
                  notice: "Page variant was successfully created."
    end

    def edit; end

    def update
      if @page_variant.update(variant_params)
        respond_to do |format|
          format.html do
            redirect_to edit_page_variant_path(@page, @page_variant),
                        notice: "Translation was successfully updated."
          end
          format.json { head :no_content }
          format.turbo_stream
        end
      else
        render :edit, status: :unprocessable_content
      end
    end

    def publish
      result = Postnhost::Publishing::PageVariants::Publish.call(page_variant: @page_variant)
      @page_variant.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html do
          redirect_to edit_page_variant_path(@page, @page_variant), **(error.present? ? { alert: error } : {})
        end
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :publish, status: result.status
        end
      end
    end

    def unpublish
      result = Postnhost::Publishing::PageVariants::Unpublish.call(page_variant: @page_variant)
      @page_variant.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html do
          redirect_to edit_page_variant_path(@page, @page_variant), **(error.present? ? { alert: error } : {})
        end
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :unpublish, status: result.status
        end
      end
    end

    def destroy
      @page_variant.destroy
      redirect_to page_variants_path(@page), notice: "Translation was successfully deleted."
    end

    def bulk_publish
      result = Postnhost::Publishing::PageVariants::PublishMany.call(page: @page, ids: params[:ids])
      error = result.errors.to_sentence unless result.success?
      error = "#{result.value[:failures].count} translation(s) failed." if result.success? && result.value[:failures].any?

      redirect_to page_variants_path(@page), **(error.present? ? { alert: error } : {})
    end

    def bulk_unpublish
      result = Postnhost::Publishing::PageVariants::UnpublishMany.call(page: @page, ids: params[:ids])
      error = result.errors.to_sentence unless result.success?
      error = "#{result.value[:failures].count} translation(s) failed." if result.success? && result.value[:failures].any?

      redirect_to page_variants_path(@page), **(error.present? ? { alert: error } : {})
    end

    def bulk_destroy
      variants = @page.page_variants.where(id: params[:ids]).where.not(generating: true)
      count = variants.count
      variants.destroy_all

      redirect_to page_variants_path(@page), notice: "#{count} translation(s) deleted successfully."
    end

    private

    def load_page
      @page = Postnhost::Page.find(params[:page_id])
    end

    def load_page_variant
      @page_variant = @page.page_variants.find(params[:id])
    end

    def ensure_variant_editable
      return unless @page_variant.generating?

      redirect_to page_variants_path(@page),
                  alert: "This translation is still in progress. You can edit it when it finishes."
    end

    def variant_params
      params.require(:page_variant).permit(:title, :title_tag, :og_title, :meta_description, :content, :language_id)
    end

    def resolve_layout
      action_name == "index" ? "postnhost/product" : "postnhost/articles"
    end
  end
end

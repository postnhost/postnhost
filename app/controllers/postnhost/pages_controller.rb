module Postnhost
  class PagesController < ApplicationController
    before_action :authenticate_user!
    before_action :load_page, only: %i[edit update destroy publish unpublish]

    layout :resolve_layout

    def index
      @pages = Postnhost::Page.includes(:page_snapshot).order(updated_at: :desc)
      @static_page_slugs = static_page_slugs
    end

    def new
      @page = current_user.pages.new
      @page.language = Postnhost::Language.blog_default
      @page.save!
      redirect_to edit_page_path(@page)
    end

    def edit; end

    def update
      if @page.update(page_params)
        respond_to do |format|
          format.html { redirect_to edit_page_path(@page) }
          format.json { head :no_content }
          format.turbo_stream { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_content }
          format.json { render json: { errors: @page.errors.full_messages }, status: :unprocessable_content }
          format.turbo_stream { head :unprocessable_content }
        end
      end
    end

    def publish
      result = Postnhost::Publishing::Pages::Publish.call(page: @page)
      @page.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html { redirect_to edit_page_path(@page), **(error.present? ? { alert: error } : {}) }
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :publish, status: result.status
        end
      end
    end

    def unpublish
      result = Postnhost::Publishing::Pages::Unpublish.call(page: @page)
      @page.reload
      error = result.errors.to_sentence unless result.success?

      respond_to do |format|
        format.html { redirect_to edit_page_path(@page), **(error.present? ? { alert: error } : {}) }
        format.turbo_stream do
          flash.now[:alert] = error if error.present?
          render :unpublish, status: result.status
        end
      end
    end

    def destroy
      @page.destroy
      redirect_to pages_path
    end

    private

    def load_page
      @page = Postnhost::Page.find(params[:id])
    end

    def page_params
      params.require(:page).permit(:title, :title_tag, :og_title, :meta_description, :content, :slug, :language_id)
    end

    def static_page_slugs
      [
        Rails.root.join("app/views/postnhost/static_pages/*.html.erb"),
        Postnhost::Engine.root.join("app/views/postnhost/static_pages/*.html.erb")
      ].flat_map { |pattern| Dir[pattern.to_s] }
       .map { |template_path| File.basename(template_path, ".html.erb") }
       .uniq
       .sort
    end

    def resolve_layout
      action_name == "index" ? "postnhost/product" : "postnhost/articles"
    end
  end
end

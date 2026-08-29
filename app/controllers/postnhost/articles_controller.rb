module Postnhost
  class ArticlesController < ApplicationController
    PAGE_SIZE = 15

    before_action :authenticate_user!
    before_action :load_article, except: %i[index new]

    layout :resolve_layout

    def index
      @status = Postnhost::Article.normalize_status(params[:status])
      @sort = Postnhost::Article.normalize_sort(params[:sort])

      articles = current_user.articles
                             .includes(:language, :article_snapshot)
                             .with_status(@status)
                             .sorted_by(@sort)

      @pagy, @articles = pagy(:offset, articles, limit: PAGE_SIZE)
    end

    def new
      @article = current_user.articles.new
      @article.language = Postnhost::Language.blog_default
      @article.save!
      redirect_to edit_article_path(@article)
    end

    def edit
      @categories = Postnhost::Category.all
      @users = Postnhost::User.order(:name, :email)
      @languages = Postnhost::Language.order(default: :desc, name: :asc)
      @articles = current_user.articles.where.not(id: @article.id).order(:title)
    end

    def update
      if @article.update(article_params)
        @article.sync_publication_schedule!
        respond_to do |format|
          format.html { redirect_to articles_path }
          format.json { head :no_content }
          format.turbo_stream
        end
      else
        @categories = Postnhost::Category.all
        @users = Postnhost::User.order(:name, :email)
        @languages = Postnhost::Language.order(default: :desc, name: :asc)
        @articles = current_user.articles.where.not(id: @article.id).order(:title)
        render :edit, status: :unprocessable_content
      end
    end

    def publish
      result = Postnhost::Publishing::Articles::Publish.call(article: @article)
      @article.reload
      respond_to do |format|
        format.html do
          redirect_to edit_article_path(@article),
                      **publication_flash(result, success: "Article has been published.")
        end
        format.turbo_stream do
          flash.now[result.success? ? :notice : :alert] = result.success? ? "Article has been published." : result.errors.to_sentence
          render :publish, status: result.status
        end
      end
    end

    def unpublish
      result = Postnhost::Publishing::Articles::Unpublish.call(article: @article)
      @article.reload
      respond_to do |format|
        format.html do
          redirect_to edit_article_path(@article),
                      **publication_flash(result, success: "Article has been unpublished.")
        end
        format.turbo_stream do
          flash.now[result.success? ? :notice : :alert] = result.success? ? "Article has been unpublished." : result.errors.to_sentence
          render :unpublish, status: result.status
        end
      end
    end

    def rollback
      version = @article.versions.find_by(id: params[:version_id])
      result = version && Postnhost::Publishing::Versions::RestoreDraft.call(record: @article, version:)
      if result&.success?
        redirect_to edit_article_path(@article), notice: "Article has been rolled back to the selected version."
      else
        redirect_to edit_article_path(@article), alert: result&.errors&.to_sentence || "Version was not found."
      end
    end

    def versions
      publication_version_id = @article.article_snapshot&.paper_trail_version_id
      @versions = @article.versions.includes(:item).sort_by do |version|
        [version.id == publication_version_id ? 0 : 1, -version.created_at.to_i]
      end
    end

    def version_preview
      @version = @article.versions.find(params[:version_id])
      @versioned_article = @version.reify
    end

    def destroy
      @article.destroy
      redirect_to articles_url
    end

    private

    def load_article
      @article = Postnhost::Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(:title, :title_tag, :og_title, :schema_headline, :schema_article_type, :slug, :meta_description,
                                      :custom_excerpt, :use_excerpt_as_meta_description, :content, :language_id, :cover_image_alt,
                                      :scheduled_at, :top_pick, author_ids: [], category_ids: [], suggested_article_ids: [])
    end

    def resolve_layout
      %w[index versions].include?(action_name) ? "postnhost/product" : "postnhost/articles"
    end

    def publication_flash(result, success:)
      result.success? ? { notice: success } : { alert: result.errors.to_sentence }
    end
  end
end

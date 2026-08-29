module Postnhost
  class Public::ArticlesController < Postnhost::PublicController
    TOP_PICKS_LIMIT = 4

    include CanonicalFirstPageRedirect
    include LanguageSwitcher
    include PublicFooterData
    include PublicHttpCaching
    include PublicPageSize
    include PublicTemplateResolvable

    layout :resolved_public_layout_template

    before_action :authenticate_user!, only: %i[preview]
    before_action :ensure_search_enabled, only: %i[search]
    before_action :redirect_page_one_to_canonical!, only: %i[index search]

    def index
      apply_public_http_cache(params[:page].to_i, template: resolve_public_template("articles/index"))
      return if performed?

      set_footer_data
      load_index_collection
      render_public_template("articles/index")
    end

    def search
      @search_query = normalized_search_query
      apply_public_http_cache(@search_query, params[:page].to_i, template: resolve_public_template("articles/index"))
      return if performed?

      set_footer_data
      load_index_collection(search_only: true)

      render_public_template("articles/index")
    end

    def show
      resolution = public_route_resolution(kind: :article, slug: params[:slug])
      apply_public_http_cache(resolution.record_id, template: resolve_public_template("articles/show"))
      return if performed?

      @article = resolution.record
      raise ActiveRecord::RecordNotFound if !localized_request? && @article.language_id != @current_language.id

      preload_article_associations

      if localized_request?
        @article_variant = @article.article_variant_snapshots.for_language(@current_language).first!
        @content = @article_variant
        @actual_language = @article_variant.language
        @primary_language = @article.language
      else
        @content = @article
        @actual_language = @current_language
        @primary_language = @current_language
      end

      @available_variants = @article.article_variant_snapshots.with_language.to_a

      set_footer_data
      render_public_template("articles/show")
    end

    def preview
      set_footer_data
      @article = Postnhost::Article.includes(:categories, :language, article_authors: :user).find(params[:id])

      @content = @article
      @actual_language = @article.language || @current_language

      @available_variants = @article.article_variants.includes(:language)

      render_public_template("articles/preview")
    end

    private

    def ensure_search_enabled
      raise_not_found unless current_setting.search_enabled?
    end

    def load_index_collection(search_only: false)
      load_top_pick_collection unless search_only || params[:page].to_i > 1

      collection = public_article_collection
      collection = collection.matching(@search_query) if search_only
      @pagy, snapshots = pagy(:offset, collection, limit: public_page_size, slots: pagination_slots)
      assign_article_collection(snapshots)
    end

    def load_top_pick_collection
      snapshots = public_article_collection.top_picks.limit(TOP_PICKS_LIMIT)

      if localized_request?
        @top_pick_article_variant_snapshots = snapshots
      else
        @top_pick_article_snapshots = snapshots
      end
    end

    def preload_article_associations
      associations = [:categories, { article_snapshot_authors: :user }]
      associations << :language if localized_request?
      ActiveRecord::Associations::Preloader.new(records: [@article], associations:).call
    end

    def public_article_collection
      if localized_request?
        Postnhost::Snapshot::ArticleVariant.for_language(@current_language)
                                           .with_language
                                           .with_categories
                                           .with_authors
                                           .recent_first
      else
        Postnhost::Snapshot::Article.for_language(@current_language)
                                    .with_categories
                                    .with_authors
                                    .recent_first
      end
    end

    def assign_article_collection(snapshots)
      if localized_request?
        @article_variant_snapshots = snapshots
      else
        @article_snapshots = snapshots
      end
    end

    def normalized_search_query
      params[:s].to_s.strip.presence
    end
  end
end

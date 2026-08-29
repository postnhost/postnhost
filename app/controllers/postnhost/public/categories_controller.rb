module Postnhost
  class Public::CategoriesController < Postnhost::PublicController
    include CanonicalFirstPageRedirect
    include LanguageSwitcher
    include PublicFooterData
    include PublicHttpCaching
    include PublicPageSize
    include PublicTemplateResolvable

    layout :resolved_public_layout_template

    before_action :redirect_page_one_to_canonical!, only: %i[index]

    def index
      resolution = public_route_resolution(kind: :category, slug: params[:category_slug])
      apply_public_http_cache(resolution.record_id, params[:page].to_i,
                              template: resolve_public_template("categories/index"))
      return if performed?

      @category = resolution.record
      ActiveRecord::Associations::Preloader.new(records: [@category], associations: :category_variants).call unless @current_language.default?
      set_category_language_data
      set_footer_data
      @pagy, snapshots = pagy(:offset, category_articles, limit: public_page_size, slots: pagination_slots)

      if localized_request?
        @article_variant_snapshots = snapshots
      else
        @article_snapshots = snapshots
      end

      render_public_template("categories/index")
    end

    private

    def set_category_language_data
      @published_category_language_ids = Postnhost::Snapshot::ArticleVariant
                                         .in_category(@category)
                                         .distinct
                                         .pluck(:language_id)
      @localized_category_fallback = localized_request? &&
                                     @published_category_language_ids.exclude?(@current_language.id)
    end

    def category_articles
      if localized_request?
        Postnhost::Snapshot::ArticleVariant.for_language(@current_language)
                                           .in_category(@category)
                                           .with_language
                                           .with_authors
                                           .recent_first
      else
        Postnhost::Snapshot::Article.for_language(@current_language)
                                    .in_category(@category)
                                    .with_authors
                                    .recent_first
      end
    end
  end
end

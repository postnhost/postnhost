module Postnhost
  class Public::AuthorsController < Postnhost::PublicController
    include CanonicalFirstPageRedirect
    include LanguageSwitcher
    include PublicFooterData
    include PublicHttpCaching
    include PublicPageSize
    include PublicTemplateResolvable

    layout :resolved_public_layout_template

    before_action :ensure_author_pages_enabled
    before_action :redirect_page_one_to_canonical!, only: %i[show]
    before_action :load_author

    def show
      apply_public_http_cache(@author, params[:page].to_i, template: resolve_public_template("authors/show"))
      return if performed?

      set_footer_data
      @pagy, snapshots = pagy(:offset, author_articles, limit: public_page_size, slots: pagination_slots)

      if localized_request?
        @article_variant_snapshots = snapshots
      else
        @article_snapshots = snapshots
      end

      render_public_template("authors/show")
    end

    private

    def ensure_author_pages_enabled
      raise_not_found unless current_setting.author_pages_enabled?
    end

    def load_author
      @author = Postnhost::User.find_by!(slug: params[:slug])
    end

    def author_articles
      if localized_request?
        Postnhost::Snapshot::ArticleVariant.for_language(@current_language)
                                           .by_author(@author)
                                           .with_language
                                           .with_categories
                                           .recent_first
      else
        Postnhost::Snapshot::Article.for_language(@current_language)
                                    .by_author(@author)
                                    .with_categories
                                    .recent_first
      end
    end
  end
end

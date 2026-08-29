module Postnhost
  module CategoryHelper
    def category_articles
      @article_snapshots || @article_variant_snapshots || []
    end

    def top_pick_articles
      @top_pick_article_snapshots || @top_pick_article_variant_snapshots || []
    end

    def localized_category_name(category, language)
      return category.name if language.nil? || language.default?

      category_variant_for_language(category, language)&.name || category.name
    end

    def localized_category_meta_description(category, language)
      return category.meta_description if language.nil? || language.default?

      category_variant_for_language(category, language)&.meta_description || category.meta_description
    end

    def category_article(item)
      item.is_a?(Postnhost::Snapshot::ArticleVariant) ? item.article_snapshot : item
    end

    def category_article_author_user(item)
      @category_article_author_cache ||= {}
      cache_key = [item.class.name, item.id || item.object_id]
      return @category_article_author_cache[cache_key] if @category_article_author_cache.key?(cache_key)

      @category_article_author_cache[cache_key] = article_authors(category_article(item)).first
    end

    def category_article_url(item)
      snapshot = category_article(item)
      return public_article_path(snapshot.slug) if item.is_a?(Postnhost::Snapshot::Article)

      localized_public_article_path(@current_language.html_lang, snapshot.slug)
    end

    private

    def category_variant_for_language(category, language)
      if category.association(:category_variants).loaded?
        category.category_variants.find { |v| v.language_id == language.id }
      else
        category.category_variants.find_by(language: language)
      end
    end
  end
end

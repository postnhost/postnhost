module Postnhost
  module NavigationHelper
    def navigation_label(item)
      return if item.blank?

      @navigation_label_cache ||= {}
      cache_key = navigation_item_cache_key(item)
      return @navigation_label_cache[cache_key] if @navigation_label_cache.key?(cache_key)

      @navigation_label_cache[cache_key] =
        item.label_for(locale_key: @current_language&.html_lang, default_locale_key: default_navigation_locale_key).presence ||
        navigation_target_label(item)
    end

    def navigation_href(item)
      return if item.blank? || item.kind != "link"

      @navigation_href_cache ||= {}
      cache_key = navigation_item_cache_key(item)
      return @navigation_href_cache[cache_key] if @navigation_href_cache.key?(cache_key)

      @navigation_href_cache[cache_key] = resolve_navigation_href(item)
    end

    def navigation_link_options(item)
      return {} unless item.target_kind == "external"

      rel_value = item.nofollow ? "noopener noreferrer nofollow" : "noopener noreferrer"
      { target: "_blank", rel: rel_value }
    end

    def default_navigation_locale_key
      @default_navigation_locale_key ||= @default_language&.html_lang || I18n.default_locale.to_s
    end

    private

    def resolve_navigation_href(item)
      case item.target_kind
      when "article"
        article = navigation_target(item)
        return unless article

        if localized_navigation?
          variant = navigation_variant(article)
          return postnhost.localized_public_article_path(@current_language.html_lang, article.slug) if variant.present?
        end

        postnhost.public_article_path(article.slug)
      when "page"
        page = navigation_target(item)
        return unless page

        if localized_navigation?
          variant = navigation_variant(page)
          return postnhost.localized_public_static_page_path(locale: @current_language.html_lang, slug: page.slug) if variant.present?
        end

        postnhost.public_static_page_path(slug: page.slug)
      when "category"
        category = navigation_target(item)
        return if category.blank?

        language_category_path(category.slug, @current_language)
      when "static_page"
        language_static_page_path(item.target_slug, @current_language)
      when "external"
        item.url
      when "text"
        nil
      end
    end

    def navigation_target_label(item)
      @navigation_target_label_cache ||= {}
      cache_key = navigation_target_cache_key(item)
      return @navigation_target_label_cache[cache_key] if @navigation_target_label_cache.key?(cache_key)

      @navigation_target_label_cache[cache_key] = resolve_navigation_target_label(item)
    end

    def resolve_navigation_target_label(item)
      case item.target_kind
      when "article"
        article = navigation_target(item)
        return if article.blank?

        if localized_navigation?
          variant = navigation_variant(article)
          return variant.title if variant.present?
        end

        article.title
      when "page"
        page = navigation_target(item)
        return if page.blank?

        if localized_navigation?
          variant = navigation_variant(page)
          return variant.title if variant.present?
        end

        page.title
      when "category"
        category = navigation_target(item)
        category.present? ? localized_category_name(category, @current_language) : nil
      when "static_page"
        item.target_slug.to_s.tr("_-", " ").humanize
      when "external"
        item.url
      when "text"
        nil
      end
    end

    def navigation_target(item)
      @navigation_target_cache.fetch(item.target_kind, {})[item.target_id]
    end

    def navigation_variant(record)
      case record
      when Postnhost::Snapshot::Article
        @navigation_variant_cache.fetch(record.class.name, {})[record.article_id]
      when Postnhost::Snapshot::Page
        @navigation_variant_cache.fetch(record.class.name, {})[record.page_id]
      end
    end

    def navigation_item_cache_key(item)
      [item.id || item.object_id, @current_language&.id, @current_language&.html_lang]
    end

    def navigation_target_cache_key(item)
      [
        item.target_kind,
        item.target_id,
        item.target_slug,
        item.url,
        @current_language&.id,
        @current_language&.html_lang
      ]
    end

    def localized_navigation?
      @current_language.present? && !@current_language.default?
    end
  end
end

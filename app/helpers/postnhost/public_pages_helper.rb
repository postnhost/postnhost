module Postnhost
  module PublicPagesHelper
    def document_lang
      return content_for(:lang) if content_for?(:lang)

      @current_language&.html_lang.presence || I18n.locale.to_s.presence || "en"
    end

    # Language switcher helpers
    def current_path_without_locale
      base_path = request.path_info.to_s
      base_path = "/" if base_path.blank?

      locale = params[:locale].presence
      stripped_path = locale.present? ? base_path.sub(%r{\A/#{Regexp.escape(locale)}(?=/|$)}, "") : base_path

      stripped_path.presence || "/"
    end

    def localized_path(language)
      base_path = current_path_without_locale
      base_path = "/" if base_path.empty?

      locale_path = if language.default
                      base_path
                    else
                      base_path == "/" ? "/#{language.html_lang}" : "/#{language.html_lang}#{base_path}"
                    end

      public_template_preview_path("#{request.script_name}#{locale_path}")
    end

    def public_template_preview_path(path)
      previewing_template = respond_to?(:user_signed_in?, true) && user_signed_in? && params[:preview_template].present?
      return path unless previewing_template

      "#{path}?preview_template=#{ERB::Util.url_encode(params[:preview_template])}"
    end

    # Language-aware navigation helpers for public pages
    def language_root_path(language)
      return postnhost.root_path unless language

      if language.default
        postnhost.root_path
      else
        postnhost.localized_root_path(locale: language.html_lang)
      end
    end

    def language_search_path(language)
      return postnhost.public_search_path unless language

      if language.default
        postnhost.public_search_path
      else
        postnhost.localized_public_search_path(language.html_lang)
      end
    end

    def language_search_url(language)
      return postnhost.public_search_url unless language

      if language.default
        postnhost.public_search_url
      else
        postnhost.localized_public_search_url(language.html_lang)
      end
    end

    def language_category_path(category_slug, language)
      return postnhost.public_category_path(category_slug) unless language

      if language.default
        postnhost.public_category_path(category_slug)
      else
        postnhost.localized_public_category_path(language.html_lang, category_slug)
      end
    end

    def language_static_page_path(page_slug, language)
      return postnhost.public_static_page_path(slug: page_slug) unless language

      if language.default
        postnhost.public_static_page_path(slug: page_slug)
      else
        postnhost.localized_public_static_page_path(locale: language.html_lang, slug: page_slug)
      end
    end

    def language_author_path(author_slug, language)
      return unless author_pages_enabled?
      return postnhost.public_author_path(author_slug) unless language

      if language.default
        postnhost.public_author_path(author_slug)
      else
        postnhost.localized_public_author_path(language.html_lang, author_slug)
      end
    end

    def language_author_url(author_slug, language)
      return unless author_pages_enabled?
      return postnhost.public_author_url(author_slug) unless language

      if language.default
        postnhost.public_author_url(author_slug)
      else
        postnhost.localized_public_author_url(language.html_lang, author_slug)
      end
    end

    # Public page metadata helpers
    def public_page_number
      params[:page].to_i
    end

    def paginated_public_page?
      public_page_number > 1
    end

    def public_blog_index_title
      if paginated_public_page?
        t(
          "postnhost.public.site.blog_meta_title_paginated",
          page: public_page_number,
          blog_meta_title: t("postnhost.public.site.blog_meta_title")
        )
      else
        t("postnhost.public.site.blog_meta_title")
      end
    end

    def public_search_query
      @search_query.presence || params[:s].to_s.strip.presence
    end

    def public_search_endpoint?
      controller_name == "articles" && action_name == "search"
    end

    def public_search_page?
      public_search_query.present?
    end

    def public_search_title
      t("postnhost.public.search.title", query: public_search_query)
    end

    def public_search_heading
      t("postnhost.public.search.heading", query: public_search_query)
    end

    def public_articles_index_title
      return public_search_title if public_search_page?
      return t("postnhost.public.search.submit") if public_search_endpoint?

      public_blog_index_title
    end

    def public_articles_index_heading
      public_search_page? ? public_search_heading : public_blog_heading
    end

    def public_search_trigger_url
      language_search_path(@current_language)
    end

    def public_blog_index_url
      if public_search_endpoint?
        paginated_public_page? ? language_search_url(@current_language) : request.original_url
      else
        paginated_public_page? ? postnhost.root_url : request.original_url
      end
    end

    def public_blog_heading
      if paginated_public_page?
        t("postnhost.public.blog.page_title", page: public_page_number)
      else
        t("postnhost.public.site.blog_tagline")
      end
    end

    def show_public_blog_subtitle?
      !paginated_public_page? && !public_search_page? && !public_search_endpoint?
    end

    def public_category_title(category)
      if paginated_public_page?
        t(
          "postnhost.public.category.page_title",
          page: public_page_number,
          category: localized_category_name(category, @current_language)
        )
      else
        t(
          "postnhost.public.category.title",
          category: localized_category_name(category, @current_language)
        )
      end
    end

    def public_category_index_url(category)
      return postnhost.public_category_url(category.slug) if @localized_category_fallback

      paginated_public_page? ? postnhost.public_category_url(category.slug) : request.original_url
    end

    def public_category_heading(category)
      if paginated_public_page?
        t(
          "postnhost.public.category.page_heading",
          page: public_page_number,
          category: localized_category_name(category, @current_language)
        )
      else
        localized_category_name(category, @current_language)
      end
    end

    def public_category_description(category)
      localized_category_meta_description(category, @current_language)
    end

    def show_public_category_description?(category)
      public_category_description(category).present? && !paginated_public_page?
    end

    # Public layout language switcher helpers
    def public_article_show_page?
      controller_name == "articles" && action_name == "show"
    end

    def public_static_page_show_page?
      controller_name == "static_pages" && action_name == "show"
    end

    def show_article_variant_language_switcher?
      return false unless public_article_show_page?
      return false if @available_variants.nil?

      if @available_variants.respond_to?(:exists?)
        @available_variants.offset(1).exists? || (@article.present? && @available_variants.exists?)
      else
        @available_variants.size > 1 || (@article.present? && @available_variants.any?)
      end
    end

    def show_page_variant_language_switcher?
      return false unless public_static_page_show_page?
      return false if @available_variants.nil?

      if @available_variants.respond_to?(:exists?)
        @available_variants.offset(1).exists? || (@page.present? && @available_variants.exists?)
      else
        @available_variants.size > 1 || (@page.present? && @available_variants.any?)
      end
    end

    def show_other_languages_switcher?
      !public_article_show_page? && !public_static_page_show_page? && @other_languages&.any?
    end

    def localized_language_options(primary)
      options = [[@current_language.name, localized_path(@current_language)]]
      primary_language = primary.is_a?(Postnhost::Snapshot::Article) ? @primary_language : primary&.language

      options << [primary_language.name, localized_path(primary_language)] if primary_language.present? && primary_language != @current_language

      return options if @available_variants.blank?

      @available_variants.each do |variant|
        next if variant.language == @current_language

        options << [variant.language.name, localized_path(variant.language)]
      end

      options.uniq { |(_, path)| path }
    end

    def default_language_options
      [[@current_language.name, localized_path(@current_language)]] +
        @other_languages.to_a.map { |language| [language.name, localized_path(language)] }
    end
  end
end

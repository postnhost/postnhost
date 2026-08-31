module Postnhost
  module ApplicationHelper
    AUTHOR_SOCIAL_FIELDS = [
      { field: :website_url, label: "Website", icon: "external-link" },
      { field: :x_url, label: "X", icon: "x" },
      { field: :linkedin_url, label: "LinkedIn", icon: "linkedin" },
      { field: :facebook_url, label: "Facebook", icon: "facebook" },
      { field: :youtube_url, label: "YouTube", icon: "youtube" },
      { field: :instagram_url, label: "Instagram", icon: "instagram" },
      { field: :threads_url, label: "Threads", icon: "threads" },
      { field: :tiktok_url, label: "TikTok", icon: "tiktok" },
      { field: :mastodon_url, label: "Mastodon", icon: "mastodon" },
      { field: :bluesky_url, label: "Bluesky", icon: "bluesky" }
    ].freeze

    def postnhost_openai_api_key_configured?
      Postnhost.config.openai_api_key.present?
    end

    def postnhost_public_locale_file_present_for?(html_lang)
      locale = html_lang.to_s.strip
      return true if locale.blank?

      Postnhost::Engine.root.join("config/locales/#{locale}.yml").exist? ||
        Rails.root.join("config/locales/#{locale}.yml").exist?
    end

    def flash_class(level)
      case level.to_sym
      when :notice then "bg-blue-50 border border-blue-200 text-blue-800  rounded-2xl"
      when :success then "bg-green-50 border border-green-200 text-green-800  rounded-2xl"
      when :error then "bg-red-50 border border-red-200 text-red-800  rounded-2xl"
      when :alert then "bg-yellow-50 border border-yellow-200 text-yellow-800  rounded-2xl"
      when :payment_required then "hidden"
      else "bg-gray-50 border border-gray-200 text-gray-800  rounded-2xl"
      end
    end

    def admin_datetime(value, format: "%B %d, %Y at %l:%M %p %Z")
      return if value.blank?

      l(value, format:)
    end

    def admin_datetime_local_value(value)
      return if value.blank?

      l(value, format: "%Y-%m-%dT%H:%M")
    end

    # Author helpers rely on the CMS user profile only.
    def author_name(user = nil)
      user ||= current_user if respond_to?(:current_user)
      return unless user.respond_to?(:name)

      user.name.presence
    end

    def author_avatar(user = nil)
      user ||= current_user if respond_to?(:current_user)
      return unless user.respond_to?(:avatar_file) && user.avatar_file?

      user.avatar_file.url
    end

    def author_initials(user = nil)
      name = author_name(user)
      return if name.blank?

      name.split.map(&:first).join.upcase[0, 2]
    end

    def author_pages_enabled?
      return @author_pages_enabled if defined?(@author_pages_enabled)

      @author_pages_enabled = current_setting.author_pages_enabled?
    end

    delegate :search_enabled?, to: :current_setting

    def article_authors(article)
      article = article_record_for_author_data(article)
      return [] unless article

      authors = article_author_records(article).map(&:user)
      authors.select { |author| author_name(author).present? }
    end

    def article_authors_cache_key(article)
      article = article_record_for_author_data(article)
      return [] unless article.respond_to?(:article_authors) || article.respond_to?(:article_snapshot_authors)

      [
        "author_pages_enabled",
        author_pages_enabled?,
        *article_author_records(article).map do |article_author|
          author = article_author.user
          [
            article_author.user_id,
            article_author.position,
            article_author.updated_at&.to_i,
            author&.updated_at&.to_i
          ]
        end
      ]
    end

    def article_author_label(author)
      author&.position.presence || t("postnhost.public.blog.author_label")
    end

    def author_social_links(author)
      return [] unless author

      AUTHOR_SOCIAL_FIELDS.filter_map do |social|
        url = normalize_external_url(author.public_send(social[:field]))
        next unless url

        social.merge(url:)
      end
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

      "#{request.script_name}#{locale_path}"
    end

    # Language-aware navigation helpers for public pages
    def language_root_path(language)
      return root_path unless language

      if language.default
        root_path
      else
        localized_root_path(locale: language.html_lang)
      end
    end

    def language_category_path(category_slug, language)
      return public_category_path(category_slug) unless language

      if language.default
        public_category_path(category_slug)
      else
        localized_public_category_path(language.html_lang, category_slug)
      end
    end

    def language_author_path(author_slug, language)
      return unless author_pages_enabled?
      return public_author_path(author_slug) unless language

      if language.default
        public_author_path(author_slug)
      else
        localized_public_author_path(language.html_lang, author_slug)
      end
    end

    def language_author_url(author_slug, language)
      return unless author_pages_enabled?
      return public_author_url(author_slug) unless language

      if language.default
        public_author_url(author_slug)
      else
        localized_public_author_url(language.html_lang, author_slug)
      end
    end

    def article_record_for_author_data(record)
      return unless record

      case record
      when Postnhost::Snapshot::ArticleVariant
        record.article_snapshot
      when Postnhost::ArticleVariant
        record.article
      else
        record
      end
    end

    def article_author_records(article)
      association_name = article.is_a?(Postnhost::Snapshot::Article) ? :article_snapshot_authors : :article_authors
      return [] unless article.respond_to?(association_name)

      @article_author_records_cache ||= {}
      cache_key = [article.class.name, article.id || article.object_id]
      return @article_author_records_cache[cache_key] if @article_author_records_cache.key?(cache_key)

      records = if article.association(association_name).loaded?
                  article.public_send(association_name).to_a
                else
                  article.public_send(association_name).order(:position).to_a
                end

      ActiveRecord::Associations::Preloader.new(records:, associations: :user).call if records.any?

      @article_author_records_cache[cache_key] = records
    end

    def normalize_external_url(value)
      raw_url = value.to_s.strip
      return if raw_url.blank?

      normalized_url = raw_url.match?(%r{\Ahttps?://}i) ? raw_url : "https://#{raw_url}"
      uri = URI.parse(normalized_url)
      return if uri.host.blank?
      return if uri.userinfo.present?

      normalized_url
    rescue URI::InvalidURIError
      nil
    end
  end
end

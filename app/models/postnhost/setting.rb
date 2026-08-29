require "uri"

module Postnhost
  class Setting < ApplicationRecord
    include Postnhost::SchemaLocalizable
    include Postnhost::PublicRevisionTouch

    self.table_name = "postnhost_settings"

    PUBLIC_PAGE_SIZE_RANGE = Postnhost::Configuration::PUBLIC_PAGE_SIZE_RANGE
    SITE_INDEXING_OPTIONS = %w[index noindex].freeze
    TIMEZONE_NAMES = ActiveSupport::TimeZone.all.map { |zone| zone.tzinfo.name }.uniq.freeze
    mount_uploader :site_logo, Postnhost::SettingAssetUploader
    mount_uploader :og_image, Postnhost::SettingAssetUploader

    has_one :navigation, class_name: "Postnhost::Navigation", dependent: :destroy, inverse_of: :setting
    has_many :site_scripts, class_name: "Postnhost::SiteScript", dependent: :destroy, inverse_of: :setting

    validates :timezone, inclusion: { in: TIMEZONE_NAMES }, allow_blank: true
    validates :site_indexing, inclusion: { in: SITE_INDEXING_OPTIONS }
    validates :public_page_size, numericality: { only_integer: true, in: PUBLIC_PAGE_SIZE_RANGE }, allow_nil: true
    validates :use_auto_header_navigation, inclusion: { in: [true, false] }
    validates :use_auto_footer_navigation, inclusion: { in: [true, false] }
    validates :author_pages_enabled, inclusion: { in: [true, false] }
    validates :search_enabled, inclusion: { in: [true, false] }
    validates :show_powered_by, inclusion: { in: [true, false] }
    validate :site_url_is_http_origin

    before_validation :normalize_site_url
    before_validation :normalize_timezone
    after_commit :clear_i18n_cache, if: :saved_change_to_locale_overrides?

    def self.current
      first_or_create!
    end

    def self.effective_timezone_name
      current.effective_timezone_name
    end

    def effective_timezone_name
      selected_timezone = timezone.presence || Postnhost.config.default_timezone
      ActiveSupport::TimeZone[selected_timezone]&.name || "UTC"
    end

    def effective_site_url
      site_url.presence || Postnhost.config.site_url
    end

    def effective_public_page_size
      public_page_size || Postnhost.config.public_page_size
    end

    def site_url_options
      return {} if effective_site_url.blank?

      uri = URI.parse(effective_site_url)
      { host: uri.host, protocol: uri.scheme, port: uri.port }
    end

    def canonical_url_for(url)
      uri = URI.parse(url)
      if effective_site_url.blank?
        uri.query = nil
        uri.fragment = nil
        return uri.to_s
      end

      path = uri.path.presence || "/"
      "#{effective_site_url}#{path}"
    end

    def site_configuration_cache_key
      [effective_site_url, effective_public_page_size, site_indexing]
    end

    def schema_settings_hash
      schema_settings.is_a?(Hash) ? schema_settings.deep_stringify_keys : {}
    end

    def schema_setting(key, default: nil)
      schema_settings_hash[key.to_s].presence || default
    end

    def current_navigation
      navigation || create_navigation!
    end

    private

    def normalize_site_url
      self.site_url = site_url.to_s.strip.chomp("/").presence
    end

    def normalize_timezone
      return self.timezone = nil if timezone.blank?

      self.timezone = ActiveSupport::TimeZone[timezone]&.tzinfo&.name || timezone
    end

    def site_url_is_http_origin
      return if site_url.blank?

      uri = URI.parse(site_url)
      return if uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil? && uri.path.blank? && uri.query.nil? && uri.fragment.nil?

      errors.add(:site_url, "must be an HTTP(S) origin without a path, query, or fragment")
    rescue URI::InvalidURIError
      errors.add(:site_url, "must be a valid URL")
    end

    def clear_i18n_cache
      Postnhost::Settings::I18nOverrides.clear_cache!
    end
  end
end

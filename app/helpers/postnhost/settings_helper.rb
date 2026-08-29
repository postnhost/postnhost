module Postnhost
  module SettingsHelper
    DEFAULT_SITE_LOGO_PATH = "postnhost/logo.webp".freeze
    DEFAULT_OG_IMAGE_PATH = "postnhost/og-image.webp".freeze
    SITE_COPY_LABELS = {
      "postnhost.public.site.schema_site_name" => "Site Name",
      "postnhost.public.site.blog_tagline" => "Tagline",
      "postnhost.public.site.blog_subtitle" => "Subtitle",
      "postnhost.public.site.blog_meta_title" => "Meta Title",
      "postnhost.public.site.blog_meta_description" => "Meta Description"
    }.freeze

    def setting_site_logo_src
      setting = setting_current
      setting&.site_logo? ? setting.site_logo.url : DEFAULT_SITE_LOGO_PATH
    end

    def setting_og_image_src
      setting = setting_current
      setting&.og_image? ? setting.og_image.url : DEFAULT_OG_IMAGE_PATH
    end

    def setting_site_logo_absolute_url
      setting = setting_current
      setting&.site_logo? ? setting.site_logo.url : asset_url(DEFAULT_SITE_LOGO_PATH)
    end

    def setting_og_image_absolute_url
      setting = setting_current
      setting&.og_image? ? setting.og_image.url : asset_url(DEFAULT_OG_IMAGE_PATH)
    end

    def render_site_scripts(placement)
      scripts = site_scripts_by_placement.fetch(placement, [])
      safe_join(scripts.map { |site_script| site_script.script.to_s.html_safe }, "\n")
    end

    def postnhost_timezone_options
      ActiveSupport::TimeZone.all.map { |timezone| ["(UTC#{timezone.formatted_offset}) #{timezone.name}", timezone.tzinfo.name] }
    end

    def translation_entries_primary
      translation_entries_site_and_advanced.first
    end

    def translation_entries_advanced
      translation_entries_site_and_advanced.last
    end

    def site_copy_label(key, include_key: false)
      label = SITE_COPY_LABELS.fetch(key, key)
      include_key && label != key ? "#{label} (#{key})" : label
    end

    def cms_template_options
      [
        ["Default", "default"],
        ["Swiss Editorial", "swiss-editorial"],
        ["Workspace Journal", "workspace-journal"]
      ]
    end

    private

    def site_scripts_by_placement
      @site_scripts_by_placement ||= setting_current.site_scripts.order(:id).group_by(&:placement)
    end

    def translation_entries_site_and_advanced
      return [[], []] if @translation_entries.blank?

      @translation_entries.partition { |key, _value| key.start_with?("postnhost.public.site.") }
    end

    def setting_current
      @setting_current ||= Postnhost::Setting.current
    end
  end
end

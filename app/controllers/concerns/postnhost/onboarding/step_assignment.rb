module Postnhost
  module Onboarding
    module StepAssignment
      extend ActiveSupport::Concern

      SITE_COPY_KEYS = %w[
        postnhost.public.site.schema_site_name
        postnhost.public.site.blog_tagline
        postnhost.public.site.blog_subtitle
        postnhost.public.site.blog_meta_title
        postnhost.public.site.blog_meta_description
      ].freeze

      LANGUAGE_OPTIONS = [
        { name: "English", html_lang: "en" },
        { name: "French", html_lang: "fr" },
        { name: "German", html_lang: "de" },
        { name: "Japanese", html_lang: "ja" },
        { name: "Korean", html_lang: "ko" },
        { name: "Portuguese", html_lang: "pt" },
        { name: "Polish", html_lang: "pl" },
        { name: "Spanish", html_lang: "es" },
        { name: "Russian", html_lang: "ru" }
      ].freeze

      private

      def load_step_assignments
        @step = current_step

        case @step
        when 1
          @user = Postnhost::User.new
        when 2
          @language_options = LANGUAGE_OPTIONS
          @selected_language_locales = session[:onboarding_language_locales].presence || [session[:onboarding_locale].presence || "en"]
          @selected_default_locale = session[:onboarding_locale].presence || "en"
        when 3
          assign_site_copy_fields
        end
      end

      def assign_site_copy_fields
        locale = session[:onboarding_locale].presence || I18n.default_locale.to_s
        @locale = locale

        setting = Postnhost::Setting.current
        @site_url = setting.site_url.presence || request.base_url
        @site_indexing = setting.site_indexing
        merged = Postnhost::Settings::I18nOverrides.editable_translations_for_locale(locale, setting.locale_overrides)
        @site_copy = SITE_COPY_KEYS.index_with { |key| merged[key].to_s }
      end
    end
  end
end

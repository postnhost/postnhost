module Postnhost
  module Settings
    module SchemaManageable
      extend ActiveSupport::Concern
      include Postnhost::SchemaHelper

      SCHEMA_SETTING_FIELDS = %w[
        organization_type
        founding_date
        founding_location
        contact_email
        contact_type
        address
        address_city
        address_country
        default_article_type
        coverage_starts_at
        coverage_ends_at
      ].freeze

      SCHEMA_ARRAY_FIELDS = %w[same_as].freeze

      private

      def set_schema_editor_state
        @schema_locale_keys = schema_locale_keys
        @schema_default_locale_key = @setting.schema_default_locale_key
        @schema_selected_locale_key = selected_schema_locale_key
        @schema_setting_values = @setting.schema_settings_hash
        @schema_translation_entries = schema_translation_entries_for(@schema_selected_locale_key)
      end

      def selected_schema_locale_key
        @schema_locale_keys ||= schema_locale_keys
        locale = params[:locale].presence || params[:locale_key].presence
        return locale if locale.present? && @schema_locale_keys.include?(locale.to_s)

        @schema_default_locale_key || @setting.schema_default_locale_key
      end

      def update_schema
        @schema_locale_keys = schema_locale_keys
        @schema_default_locale_key = @setting.schema_default_locale_key
        locale_key = selected_schema_locale_key
        merged_schema_settings = @setting.schema_settings_hash.merge(schema_settings_params)
        merged_schema_overrides = merge_schema_locale_overrides(
          @setting.schema_locale_overrides_hash,
          locale_key,
          schema_translation_params
        )

        if @setting.update(schema_settings: merged_schema_settings, schema_locale_overrides: merged_schema_overrides)
          redirect_to edit_settings_path(section: "schema", locale: locale_key),
                      notice: "Schema settings were successfully updated."
        else
          set_schema_editor_state
          @schema_setting_values = merged_schema_settings
          @schema_translation_entries = @schema_translation_entries.merge(schema_translation_params.stringify_keys)
          render :edit, status: :unprocessable_content
        end
      end

      def schema_locale_keys
        keys = Postnhost::Language.pluck(:html_lang).compact.uniq
        return [I18n.default_locale.to_s] if keys.empty?

        return keys unless keys.include?("en")

        ["en"] + keys.reject { |locale| locale == "en" }
      end

      def schema_translation_entries_for(locale)
        SETTINGS_TEXT_OVERRIDE_FIELDS.index_with do |field|
          @setting.schema_text_for(locale:, key: field, fallback: schema_text_fallback(field))
        end
      end

      def schema_translation_params
        translations = params.fetch(:schema_translations, ActionController::Parameters.new).permit!
        SETTINGS_TEXT_OVERRIDE_FIELDS.index_with do |field|
          translations[field]
        end
      end

      def schema_settings_params
        settings_params = params.fetch(:schema_settings, ActionController::Parameters.new).permit!
        merged = SCHEMA_SETTING_FIELDS.index_with { |field| settings_params[field] }

        SCHEMA_ARRAY_FIELDS.each do |field|
          merged[field] = schema_multiline_to_array(settings_params[field])
        end

        merged["policies"] = schema_policy_fields.keys.index_with do |key|
          settings_params.dig("policies", key)
        end

        merged.transform_values do |value|
          value.is_a?(String) ? value.strip : value
        end
      end

      def merge_schema_locale_overrides(current_overrides, locale_key, edited_translations)
        locale = locale_key.to_s
        normalized = current_overrides.deep_dup
        normalized[locale] ||= {}

        edited_translations.each do |field, value|
          text = value.to_s.strip
          if text.blank?
            normalized[locale].delete(field)
            next
          end

          if locale != @schema_default_locale_key && text == default_locale_schema_value(field)
            normalized[locale].delete(field)
            next
          end

          normalized[locale][field] = text
        end

        normalized.delete(locale) if normalized[locale].blank?
        normalized
      end

      def default_locale_schema_value(field)
        @setting.schema_text_for(locale: @schema_default_locale_key, key: field, fallback: schema_text_fallback(field))
      end

      def schema_text_fallback(field)
        case field.to_s
        when "website_name", "organization_name"
          I18n.t("postnhost.public.site.schema_site_name")
        when "website_description", "organization_description"
          I18n.t("postnhost.public.site.blog_meta_description")
        end
      end
    end
  end
end

module Postnhost
  module Users
    module SchemaManageable
      extend ActiveSupport::Concern
      include Postnhost::SchemaHelper

      USER_SCHEMA_PROFILE_FIELDS = %w[
        same_as
        image_url
        knows_language
        alumni_type
      ].freeze

      USER_SCHEMA_TEXT_FIELDS = %w[
        name
        job_title
        bio
        knows_about
        alumni_of
        awards
      ].freeze

      private

      def set_user_schema_editor_state
        @schema_locale_keys = user_schema_locale_keys
        @schema_default_locale_key = user_schema_default_locale_key
        @schema_selected_locale_key = selected_user_schema_locale_key
        @schema_profile_values = @user.schema_profile_hash
        @schema_translation_entries = user_schema_translation_entries_for(@schema_selected_locale_key)
      end

      def selected_user_schema_locale_key
        @schema_locale_keys ||= user_schema_locale_keys
        locale = params[:locale].presence || params[:locale_key].presence
        return locale if locale.present? && @schema_locale_keys.include?(locale.to_s)

        user_schema_default_locale_key
      end

      def user_schema_default_locale_key
        Postnhost::Language.find_by(default: true)&.html_lang.presence || I18n.default_locale.to_s
      end

      def user_schema_locale_keys
        keys = Postnhost::Language.pluck(:html_lang).compact.uniq
        return [user_schema_default_locale_key] if keys.empty?

        return keys unless keys.include?("en")

        ["en"] + keys.reject { |locale| locale == "en" }
      end

      def user_schema_profile_params
        settings_params = params.fetch(:schema_profile, ActionController::Parameters.new).permit!
        USER_SCHEMA_PROFILE_FIELDS.index_with do |field|
          if %w[same_as knows_language].include?(field)
            schema_multiline_to_array(settings_params[field])
          else
            settings_params[field].to_s.strip
          end
        end
      end

      def user_schema_translation_params
        translations = params.fetch(:schema_translations, ActionController::Parameters.new).permit!
        USER_SCHEMA_TEXT_FIELDS.index_with do |field|
          translations[field].to_s.strip
        end
      end

      def user_schema_translation_entries_for(locale)
        USER_SCHEMA_TEXT_FIELDS.index_with do |field|
          @user.schema_text_for(locale:, key: field, fallback: user_schema_fallback(field))
        end
      end

      def merge_user_schema_locale_overrides(current_overrides, locale_key, edited_translations)
        locale = locale_key.to_s
        normalized = current_overrides.deep_dup
        normalized[locale] ||= {}

        edited_translations.each do |field, value|
          if value.blank?
            normalized[locale].delete(field)
            next
          end

          if locale != user_schema_default_locale_key && value == user_default_schema_value(field)
            normalized[locale].delete(field)
            next
          end

          normalized[locale][field] = value
        end

        normalized.delete(locale) if normalized[locale].blank?
        normalized
      end

      def user_default_schema_value(field)
        @user.schema_text_for(locale: user_schema_default_locale_key, key: field, fallback: user_schema_fallback(field))
      end

      def user_schema_fallback(field)
        case field.to_s
        when "name"
          @user.name
        when "job_title"
          @user.position
        when "bio"
          @user.bio
        else
          ""
        end
      end
    end
  end
end

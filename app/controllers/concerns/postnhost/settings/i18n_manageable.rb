module Postnhost
  module Settings
    module I18nManageable
      extend ActiveSupport::Concern

      private

      def translations_params
        params.fetch(:translations, ActionController::Parameters.new).permit!.to_h
      end

      def selected_locale_key
        locale_keys = @locale_keys || locale_keys_for_i18n
        locale = params[:locale].presence || params[:locale_key].presence
        if locale.present?
          locale_key = locale.to_s
          return locale_key if locale_keys.include?(locale_key)
        end

        locale_keys.first
      end

      def update_i18n
        locale = selected_locale_key
        if locale.blank?
          @setting.errors.add(:base, "Create at least one language before editing i18n settings.")
          set_i18n_editor_state
          render :edit, status: :unprocessable_content
          return
        end

        merged_overrides = Postnhost::Settings::I18nOverrides.merge_locale_overrides(
          @setting.locale_overrides, locale, translations_params
        )

        if @setting.update(locale_overrides: merged_overrides)
          redirect_to edit_settings_path(section: "i18n", locale: locale),
                      notice: "I18n settings were successfully updated."
        else
          set_i18n_editor_state
          @translation_entries = @translation_entries.merge(translations_params.transform_keys(&:to_s))
          render :edit, status: :unprocessable_content
        end
      end

      def set_i18n_editor_state
        @locale_keys = locale_keys_for_i18n
        @selected_locale_key = selected_locale_key
        @translation_entries = Postnhost::Settings::I18nOverrides.editable_translations_for_locale(
          @selected_locale_key,
          @setting.locale_overrides
        )
      end

      def locale_keys_for_i18n
        allowed_locales = Postnhost::Language.pluck(:html_lang).compact
        Postnhost::Settings::I18nOverrides.locale_keys(@setting.locale_overrides, allowed_locales: allowed_locales)
      end
    end
  end
end

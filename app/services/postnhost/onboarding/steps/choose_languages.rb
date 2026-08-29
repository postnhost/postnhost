module Postnhost
  module Onboarding
    module Steps
      class ChooseLanguages < Base
        def call
          return restart_at_admin_account unless pending_user

          options_by_locale = LANGUAGE_OPTIONS.index_by { |option| option[:html_lang] }
          locales = selected_locales
          default_locale = selected_default_locale
          payload = language_selection_payload(locales:, default_locale:)

          return render_show(**payload, alert: "Select at least one language.") if locales.empty?
          return render_show(**payload, alert: "Choose valid languages.") if locales.any? { |locale| !options_by_locale.key?(locale) }

          return render_show(**payload, alert: "Default language must be one of the selected languages.") unless locales.include?(default_locale)

          replace_languages!(locales:, default_locale:, options_by_locale:)
          advance_session(locales:, default_locale:)
          redirect_onboarding
        end

        private

        def replace_languages!(locales:, default_locale:, options_by_locale:)
          Postnhost::Language.transaction do
            Postnhost::Language.destroy_all
            locales.each do |locale|
              option = options_by_locale.fetch(locale)
              Postnhost::Language.create!(
                name: option[:name],
                html_lang: option[:html_lang],
                default: option[:html_lang] == default_locale
              )
            end
          end
        end

        def advance_session(locales:, default_locale:)
          session[:onboarding_locale] = default_locale
          session[:onboarding_language_locales] = locales
          session[:onboarding_step] = 3
        end

        def language_selection_payload(locales:, default_locale:)
          {
            step: 2,
            language_options: LANGUAGE_OPTIONS,
            selected_language_locales: locales,
            selected_default_locale: default_locale
          }
        end

        def selected_locales
          locales = Array(params[:language_locales]).map(&:to_s).compact_blank.uniq
          locales = [params[:html_lang].to_s] if locales.empty? && params[:html_lang].present?
          locales
        end

        def selected_default_locale
          params[:default_locale].presence || params[:html_lang].presence || "en"
        end
      end
    end
  end
end

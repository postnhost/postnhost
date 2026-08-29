module Postnhost
  module Onboarding
    module Steps
      class SetSiteMetadata < Base
        def call
          return restart_at_admin_account unless pending_user

          locale = session[:onboarding_locale].presence || I18n.default_locale.to_s
          translations = translation_params
          setting = Postnhost::Setting.current
          merged = Postnhost::Settings::I18nOverrides.merge_locale_overrides(
            setting.locale_overrides,
            locale,
            translations
          )

          unless setting.update(
            locale_overrides: merged,
            site_url: params[:site_url],
            site_indexing: params[:site_indexing]
          )
            return render_show(
              **site_metadata_payload(
                values: translations,
                locale:,
                site_url: params[:site_url],
                site_indexing: params[:site_indexing]
              ),
              alert: setting_error_message(setting)
            )
          end

          session[:onboarding_step] = 4
          redirect_onboarding
        end

        private

        def setting_error_message(setting)
          site_url_error = setting.errors[:site_url].to_sentence
          return "Site URL #{site_url_error}" if site_url_error.present?

          setting.errors.full_messages.to_sentence.presence || "Could not save site settings."
        end

        def site_metadata_payload(values:, locale:, site_url:, site_indexing:)
          {
            step: 3,
            locale:,
            site_url: site_url.to_s,
            site_indexing: site_indexing.to_s,
            site_copy: SITE_COPY_KEYS.index_with { |key| values[key].to_s }
          }
        end

        def translation_params
          raw = params[:translations]
          permitted =
            if raw.is_a?(ActionController::Parameters)
              raw.permit(*SITE_COPY_KEYS)
            else
              {}
            end

          SITE_COPY_KEYS.index_with { |key| permitted[key].to_s }
        end
      end
    end
  end
end

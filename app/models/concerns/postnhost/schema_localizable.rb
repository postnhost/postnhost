module Postnhost
  module SchemaLocalizable
    extend ActiveSupport::Concern

    def schema_locale_overrides_hash
      schema_locale_overrides.is_a?(Hash) ? schema_locale_overrides.deep_stringify_keys : {}
    end

    def schema_translations_for(locale)
      schema_locale_overrides_hash.fetch(locale.to_s, {})
    end

    def schema_text_for(locale:, key:, fallback:)
      field = key.to_s
      value = schema_translations_for(locale)[field].presence
      return value if value.present?

      default_locale_value = schema_translations_for(schema_default_locale_key)[field].presence
      return default_locale_value if default_locale_value.present?

      fallback
    end

    def schema_default_locale_key
      @schema_default_locale_key ||= Postnhost::Language.find_by(default: true)&.html_lang.presence || I18n.default_locale.to_s
    end
  end
end

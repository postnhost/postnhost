module Postnhost
  module Settings
    module I18nPatch
      def translate(locale, key, options = {})
        separator = options[:separator] || I18n.default_separator
        override = Postnhost::Settings::I18nOverrides.lookup_override(
          key,
          locale: locale,
          scope: options[:scope],
          separator: separator
        )
        return super if override.nil?

        Postnhost::Settings::I18nOverrides.interpolate(override, options)
      end
    end
  end
end

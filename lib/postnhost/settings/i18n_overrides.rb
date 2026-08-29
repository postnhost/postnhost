module Postnhost
  module Settings
    module I18nOverrides
      module_function

      CACHE_KEY = "postnhost/settings/i18n_overrides"
      TRANSLATION_NAMESPACE = "postnhost."
      TRANSLATION_CONTROL_KEYS = %i[default scope locale raise throw separator fallback format resolve object].freeze

      def locale_keys(overrides, allowed_locales: nil)
        locales = (all_locales + normalize_overrides(overrides).keys).uniq.sort
        locales &= allowed_locales.map(&:to_s) unless allowed_locales.nil?
        return locales unless locales.include?("en")

        ["en"] + locales.reject { |locale| locale == "en" }
      end

      def editable_translations_for_locale(locale, overrides)
        return {} if locale.blank?

        locale_key = locale.to_s
        base_translations = namespaced_translations(base_flat_translations(locale_key))
        override_translations = namespaced_translations(normalize_overrides(overrides).fetch(locale_key, {}))
        base_translations.merge(override_translations)
      end

      def merge_locale_overrides(current_overrides, locale, edited_translations)
        locale_key = locale.to_s
        normalized = normalize_overrides(current_overrides)
        base = base_flat_translations(locale_key)

        compacted = edited_translations.each_with_object({}) do |(key, value), result|
          key_path = key.to_s
          next unless key_path.start_with?(TRANSLATION_NAMESPACE)

          text = value.to_s
          next if text.blank?
          next if base[key_path] == text

          result[key_path] = text
        end

        normalized[locale_key] = compacted
        normalized.delete(locale_key) if compacted.empty?
        normalized
      end

      def lookup_override(key, locale: I18n.locale, scope: nil, separator: I18n.default_separator, overrides: nil)
        keys = I18n.normalize_keys(locale, key, scope, separator)[1..]
        return nil if keys.blank?

        translation_key = keys.join(".")
        return nil unless translation_key.start_with?(TRANSLATION_NAMESPACE)

        source_overrides = overrides.nil? ? cached_overrides : normalize_overrides(overrides)
        source_overrides.dig(locale.to_s, translation_key)
      end

      def interpolate(value, options)
        return value unless value.is_a?(String)

        interpolation_options = options.except(*TRANSLATION_CONTROL_KEYS)
        return value if interpolation_options.blank?

        value % interpolation_options.symbolize_keys
      rescue KeyError
        value
      end

      def cached_overrides
        Rails.cache.fetch(CACHE_KEY) do
          normalize_overrides(Postnhost::Setting.current.locale_overrides)
        end
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
        {}
      end

      def clear_cache!
        Rails.cache.delete(CACHE_KEY)
      end

      def all_locales
        @all_locales ||= locale_file_paths.map { |path| File.basename(path, ".yml") }.uniq
      end

      def base_flat_translations(locale)
        base_flat_translations_by_locale.fetch(locale.to_s, base_flat_translations_by_locale.fetch(I18n.default_locale.to_s, {}))
      end

      def base_flat_translations_by_locale
        @base_flat_translations_by_locale ||= locale_file_paths.each_with_object({}) do |path, result|
          locale = File.basename(path, ".yml")
          document = YAML.safe_load_file(path, aliases: true) || {}
          flattened = flatten_hash(normalize_hash(document[locale] || {}))
          result[locale] = (result[locale] || {}).merge(flattened)
        end.freeze
      end

      def locale_file_paths
        engine_root = defined?(Postnhost::Engine) ? Postnhost::Engine.root : nil
        return engine_root.glob("config/locales/*.yml") if engine_root

        Rails.root.glob("config/locales/*.yml")
      end

      def normalize_overrides(overrides)
        return {} unless overrides.is_a?(Hash)

        overrides.each_with_object({}) do |(locale, translations), result|
          next unless translations.is_a?(Hash)

          result[locale.to_s] = normalize_hash(translations)
        end
      end

      def normalize_hash(hash)
        hash.deep_stringify_keys
      end

      def flatten_hash(hash, prefix = nil, result = {})
        hash.each do |key, value|
          path = [prefix, key.to_s].compact.join(".")
          if value.is_a?(Hash)
            flatten_hash(value, path, result)
          else
            result[path] = value.to_s
          end
        end
        result
      end

      def namespaced_translations(translations)
        translations.select { |key, _| key.to_s.start_with?(TRANSLATION_NAMESPACE) }
      end
    end
  end
end

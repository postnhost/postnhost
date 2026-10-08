module Postnhost
  module Management
    module SchemaFields
      TEXT = { type: %w[string null] }.freeze
      STRINGS = { type: "array", items: { type: "string" }, maxItems: 100 }.freeze

      def self.settings
        fields = Postnhost::Settings::SchemaManageable::SCHEMA_SETTING_FIELDS.index_with { TEXT }
        fields["same_as"] = STRINGS
        fields["policies"] = { type: "object", properties: Postnhost::SchemaHelper::POLICY_FIELDS.keys.index_with { TEXT }, additionalProperties: false }
        { type: "object", properties: fields, additionalProperties: false }
      end

      def self.profile
        fields = Postnhost::Users::SchemaManageable::USER_SCHEMA_PROFILE_FIELDS.index_with { |field| %w[same_as knows_language].include?(field) ? STRINGS : TEXT }
        { type: "object", properties: fields, additionalProperties: false }
      end

      def self.overrides(resource)
        fields = resource == "users" ? Postnhost::Users::SchemaManageable::USER_SCHEMA_TEXT_FIELDS : Postnhost::SchemaHelper::SETTINGS_TEXT_OVERRIDE_FIELDS
        { type: "object", additionalProperties: { type: "object", properties: fields.index_with { TEXT }, additionalProperties: false } }
      end
    end
  end
end

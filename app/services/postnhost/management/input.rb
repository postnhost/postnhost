module Postnhost
  module Management
    module Input
      TYPES = {
        "object" => [Hash],
        "array" => [Array],
        "integer" => [Integer],
        "string" => [String],
        "boolean" => [TrueClass, FalseClass],
        "null" => [NilClass]
      }.freeze

      def self.validate!(value, schema, path = "arguments")
        valid = Array(schema[:type]).any? do |type|
          TYPES.fetch(type).any? { |klass| value.is_a?(klass) }
        end
        raise ArgumentError, "#{path} has an invalid type" unless valid

        Time.iso8601(value) if schema[:format] == "date-time" && value

        case value
        when Hash
          validate_object!(value, schema, path)
        when Array
          raise ArgumentError, "#{path} has an invalid length" if value.size < schema.fetch(:minItems, 0) || value.size > schema.fetch(:maxItems, 1000)
          raise ArgumentError, "#{path} must contain unique values" if schema[:uniqueItems] && value.uniq != value

          value.each { |item| validate!(item, schema[:items], path) } if schema[:items]
        when Integer
          raise ArgumentError, "#{path} is out of range" if value < schema.fetch(:minimum, value) || value > schema.fetch(:maximum, value)
        end
      end

      def self.validate_object!(value, schema, path)
        properties = schema.fetch(:properties, {}).stringify_keys
        missing = schema.fetch(:required, []) - value.keys
        raise ArgumentError, "#{path} requires #{missing.join(', ')}" if missing.any?

        unknown = value.keys - properties.keys
        raise ArgumentError, "#{path} contains unknown fields: #{unknown.join(', ')}" if schema[:additionalProperties] == false && unknown.any?

        value.each do |key, item|
          child = properties[key] || schema[:additionalProperties]
          validate!(item, child, "#{path}.#{key}") if child.is_a?(Hash)
        end
      end
    end
  end
end

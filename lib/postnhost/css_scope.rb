require "crass"
require "fileutils"

module Postnhost
  class CssScope
    ROOT_SELECTOR = "html[data-postnhost]"
    ROOT_OR_DESCENDANT_SELECTOR = ":is(#{ROOT_SELECTOR}, #{ROOT_SELECTOR} *)"
    GROUP_AT_RULES = %w[container layer media starting-style supports].freeze

    class << self
      def call(css)
        rules = Crass::Parser.parse_stylesheet(css, preserve_comments: true)
        scope_rules(rules)
        Crass::Parser.stringify(rules)
      end

      def scope_file(input_path, output_path = input_path)
        output_path = File.expand_path(output_path)
        FileUtils.mkdir_p(File.dirname(output_path))
        temporary_path = "#{output_path}.tmp"
        File.write(temporary_path, call(File.read(input_path)))
        FileUtils.mv(temporary_path, output_path)
      ensure
        FileUtils.rm_f(temporary_path) if temporary_path
      end

      private

      def scope_rules(rules)
        rules.each do |rule|
          case rule[:node]
          when :style_rule
            scope_style_rule(rule)
          when :at_rule
            scope_at_rule(rule)
          end
        end
      end

      def scope_at_rule(rule)
        return unless rule[:block] && GROUP_AT_RULES.include?(rule[:name])

        nested_rules = Crass::Parser.parse_rules(rule[:block], preserve_comments: true)
        scope_rules(nested_rules)
        rule[:block] = nested_rules
      end

      def scope_style_rule(rule)
        selectors = split_selectors(rule.dig(:selector, :tokens)).map { |selector| scope_selector(selector) }.uniq
        scoped_rule = Crass::Parser.parse_rules("#{selectors.join(',')}{}").first
        rule[:selector] = scoped_rule[:selector]
      end

      def split_selectors(tokens)
        selectors = tokens.each_with_object([[]]) do |token, groups|
          if token[:node] == :comma
            groups << []
          else
            groups.last << token
          end
        end

        selectors.map { |selector_tokens| Crass::Parser.stringify(selector_tokens).strip }
      end

      def scope_selector(selector)
        return ROOT_SELECTOR if selector.match?(/\A(?::root|:host)\z/)
        return selector.sub(/\A:root/, ROOT_SELECTOR) if selector.match?(/\A:root(?=$|[\s.#\[:>+~])/)
        return selector.sub(/\Ahtml/, ROOT_SELECTOR) if selector.match?(/\Ahtml(?=$|[\s.#\[:>+~])/)
        return selector.sub(/\A\*/, ROOT_OR_DESCENDANT_SELECTOR) if selector.start_with?("*")
        return "#{ROOT_OR_DESCENDANT_SELECTOR}#{selector}" if selector.match?(/\A[.#\[:]/)

        "#{ROOT_SELECTOR} #{selector}"
      end
    end
  end
end

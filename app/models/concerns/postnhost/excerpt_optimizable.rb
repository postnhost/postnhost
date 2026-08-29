module Postnhost
  module ExcerptOptimizable
    extend ActiveSupport::Concern

    CUSTOM_EXCERPT_MAX_CHARS = 160

    included do
      validate :custom_excerpt_length_within_limit
      before_validation :populate_auto_excerpt, if: :should_populate_auto_excerpt?
    end

    class_methods do
      def custom_excerpt_max_chars
        CUSTOM_EXCERPT_MAX_CHARS
      end

      def computed_auto_excerpt(content)
        plain_content = plain_text_with_spacing(content.to_s)
        return if plain_content.blank?

        sentence_excerpt = plain_content[/\A(?:.*?[.!?](?:\s+|$)){1,2}/m]&.strip
        fallback_excerpt = sentence_excerpt.presence || plain_content
        return fallback_excerpt if fallback_excerpt.length <= custom_excerpt_max_chars

        "#{fallback_excerpt[0, custom_excerpt_max_chars].rstrip}..."
      end

      private

      def plain_text_with_spacing(content)
        return content.squish unless content.include?("<")

        content_with_breaks = content.gsub(%r{</(p|div|li|h[1-6]|blockquote|pre|tr|td|th)>|<br\s*/?>}i, " ")
        ActionController::Base.helpers.strip_tags(content_with_breaks).squish
      end
    end

    private

    def custom_excerpt_length_within_limit
      return if custom_excerpt.blank?

      excerpt = custom_excerpt.to_s.squish
      return if excerpt.length <= self.class.custom_excerpt_max_chars

      errors.add(:custom_excerpt, "must be #{self.class.custom_excerpt_max_chars} characters or fewer")
    end

    def should_populate_auto_excerpt?
      will_save_change_to_content? || auto_excerpt.blank?
    end

    def populate_auto_excerpt
      self.auto_excerpt = self.class.computed_auto_excerpt(content)
    end
  end
end

module Postnhost
  module PrimaryLanguageGuard
    extend ActiveSupport::Concern

    included do
      validate :primary_language_must_not_duplicate_a_variant
    end

    private

    def primary_language_must_not_duplicate_a_variant
      return if language_id.blank?
      return unless translation_variants.exists?(language_id: language_id)

      errors.add(:language_id, "cannot duplicate an existing translation")
    end
  end
end

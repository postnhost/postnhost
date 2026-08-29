module Postnhost
  class CategoryVariant < ApplicationRecord
    belongs_to :category, touch: true
    belongs_to :language

    broadcasts_refreshes_to ->(r) { "category_variants_#{r.category_id}" }

    validates :category_id, uniqueness: { scope: :language_id }
    validates :name, presence: true, unless: :generating?
    validate :language_must_not_be_blog_default

    private

    def language_must_not_be_blog_default
      return if language_id.blank?

      default = Postnhost::Language.blog_default
      return if default.nil?
      return unless language_id == default.id

      errors.add(:language_id, "cannot be the site default language; edit the category for that locale")
    end
  end
end

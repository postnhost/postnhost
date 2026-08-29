module Postnhost
  class ArticleSuggestion < ApplicationRecord
    belongs_to :article, touch: true
    belongs_to :suggested_article, class_name: "Postnhost::Article"

    validates :suggested_article_id, uniqueness: { scope: :article_id }
    validate :cannot_suggest_self

    default_scope { order(:position) }

    private

    def cannot_suggest_self
      return unless article_id == suggested_article_id

      errors.add(:suggested_article, "can't be the same as the article")
    end
  end
end

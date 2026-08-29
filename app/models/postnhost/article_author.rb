module Postnhost
  class ArticleAuthor < ApplicationRecord
    belongs_to :article, touch: true
    belongs_to :user, class_name: "Postnhost::User"

    before_validation :assign_position, on: :create

    validates :user_id, uniqueness: { scope: :article_id }

    default_scope { order(:position) }

    private

    def assign_position
      return if position.present? && position.positive?

      self.position = article&.article_authors&.maximum(:position).to_i + 1
    end
  end
end

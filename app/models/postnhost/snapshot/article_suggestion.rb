module Postnhost
  class Snapshot::ArticleSuggestion < ApplicationRecord
    self.table_name = "postnhost_article_snapshot_suggestions"

    belongs_to :article_snapshot, class_name: "Postnhost::Snapshot::Article", inverse_of: :article_snapshot_suggestions
    belongs_to :suggested_article, class_name: "Postnhost::Article"

    validates :suggested_article_id, :position, uniqueness: { scope: :article_snapshot_id }
    validates :position, numericality: { greater_than_or_equal_to: 0 }
  end
end

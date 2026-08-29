module Postnhost
  class Snapshot::ArticleAuthor < ApplicationRecord
    self.table_name = "postnhost_article_snapshot_authors"

    belongs_to :article_snapshot, class_name: "Postnhost::Snapshot::Article", inverse_of: :article_snapshot_authors
    belongs_to :user, class_name: "Postnhost::User"

    validates :user_id, :position, uniqueness: { scope: :article_snapshot_id }
    validates :position, numericality: { greater_than_or_equal_to: 0 }
  end
end

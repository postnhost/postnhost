module Postnhost
  class Snapshot::ArticleCategory < ApplicationRecord
    self.table_name = "postnhost_article_snapshot_categories"

    belongs_to :article_snapshot, class_name: "Postnhost::Snapshot::Article", inverse_of: :article_snapshot_categories
    belongs_to :category, class_name: "Postnhost::Category"

    validates :category_id, uniqueness: { scope: :article_snapshot_id }
  end
end

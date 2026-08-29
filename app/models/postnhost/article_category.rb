module Postnhost
  class ArticleCategory < ApplicationRecord
    belongs_to :article, touch: true
    belongs_to :category, counter_cache: :articles_count, touch: true

    validates :article_id, uniqueness: { scope: :category_id }
  end
end

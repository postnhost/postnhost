module Postnhost
  class ArticleVariant < ApplicationRecord
    include ExcerptOptimizable

    has_paper_trail versions: { class_name: "Postnhost::Version" },
                    only: %i[title title_tag og_title schema_headline meta_description custom_excerpt use_excerpt_as_meta_description content],
                    on: []

    belongs_to :article, counter_cache: true, touch: true
    belongs_to :language, counter_cache: true
    has_one :user, through: :article
    has_one :article_variant_snapshot, class_name: "Postnhost::Snapshot::ArticleVariant", dependent: :destroy

    broadcasts_refreshes_to ->(r) { "article_variants_#{r.article_id}" }

    validates :article_id, uniqueness: { scope: :language_id }

    scope :published, -> { joins(:article_variant_snapshot) }

    def published?
      article_variant_snapshot.present?
    end

    def unpublished_changes?
      article_variant_snapshot&.differs_from?(self) || false
    end
  end
end

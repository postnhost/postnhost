module Postnhost
  class Snapshot::ArticleVariant < ApplicationRecord
    self.table_name = "postnhost_article_variant_snapshots"

    SCALAR_ATTRIBUTES = %i[
      language_id title title_tag og_title schema_headline meta_description custom_excerpt auto_excerpt
      use_excerpt_as_meta_description content
    ].freeze

    belongs_to :article_variant, class_name: "Postnhost::ArticleVariant"
    belongs_to :article, class_name: "Postnhost::Article"
    belongs_to :article_snapshot, class_name: "Postnhost::Snapshot::Article",
                                  foreign_key: :article_id, primary_key: :article_id,
                                  inverse_of: :article_variant_snapshots
    belongs_to :language, class_name: "Postnhost::Language"
    belongs_to :paper_trail_version, class_name: "Postnhost::Version"

    validates :title, :content, :published_at, presence: true
    validates :article_variant_id, :paper_trail_version_id, uniqueness: true
    validates :article_id, uniqueness: { scope: :language_id }

    scope :for_language, ->(language) { where(language:) }
    scope :top_picks, lambda {
      joins(:article_snapshot).merge(Postnhost::Snapshot::Article.top_picks)
    }
    scope :by_author, lambda { |author|
      joins(:article_snapshot).merge(Postnhost::Snapshot::Article.by_author(author))
    }
    scope :in_category, lambda { |category|
      joins(:article_snapshot).merge(Postnhost::Snapshot::Article.in_category(category))
    }
    scope :recent_first, lambda {
      joins(:article_snapshot).merge(Postnhost::Snapshot::Article.recent_first)
    }
    scope :with_language, -> { includes(:language) }
    scope :with_categories, -> { includes(article_snapshot: :categories) }
    scope :with_authors, -> { includes(article_snapshot: { article_snapshot_authors: :user }) }

    def self.matching(query)
      return all if query.blank?

      where(
        <<~SQL.squish,
          LOWER(postnhost_article_variant_snapshots.title) LIKE :search OR
          LOWER(postnhost_article_variant_snapshots.content) LIKE :search OR
          LOWER(postnhost_article_variant_snapshots.meta_description) LIKE :search
        SQL
        search: "%#{sanitize_sql_like(query.downcase)}%"
      )
    end

    def published?
      true
    end

    def differs_from?(draft)
      SCALAR_ATTRIBUTES.any? { |attribute| public_send(attribute) != draft.public_send(attribute) }
    end
  end
end

module Postnhost
  class Snapshot::Article < ApplicationRecord
    self.table_name = "postnhost_article_snapshots"

    MAX_SUGGESTIONS = 3
    SCALAR_ATTRIBUTES = %i[
      language_id title title_tag og_title schema_headline schema_article_type meta_description
      custom_excerpt auto_excerpt use_excerpt_as_meta_description content slug cover_image_alt top_pick
    ].freeze

    belongs_to :article, class_name: "Postnhost::Article"
    belongs_to :language, class_name: "Postnhost::Language"
    belongs_to :paper_trail_version, class_name: "Postnhost::Version"

    has_many :article_snapshot_categories, class_name: "Postnhost::Snapshot::ArticleCategory",
                                           foreign_key: :article_snapshot_id, dependent: :destroy,
                                           inverse_of: :article_snapshot
    has_many :categories, through: :article_snapshot_categories
    has_many :article_snapshot_authors, -> { order(:position) }, class_name: "Postnhost::Snapshot::ArticleAuthor",
                                                                 foreign_key: :article_snapshot_id,
                                                                 dependent: :destroy, inverse_of: :article_snapshot
    has_many :authors, through: :article_snapshot_authors, source: :user
    has_many :article_snapshot_suggestions, -> { order(:position) },
             class_name: "Postnhost::Snapshot::ArticleSuggestion", foreign_key: :article_snapshot_id,
             dependent: :destroy, inverse_of: :article_snapshot
    # Variant snapshots intentionally survive base unpublishing.
    has_many :article_variant_snapshots, class_name: "Postnhost::Snapshot::ArticleVariant", primary_key: :article_id,
                                         inverse_of: :article_snapshot, dependent: nil

    validates :title, :content, :slug, :published_at, presence: true
    validates :article_id, :paper_trail_version_id, :slug, uniqueness: true
    validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }

    scope :for_language, ->(language) { where(language:) }
    scope :top_picks, -> { where(top_pick: true) }
    scope :by_author, lambda { |author|
      joins(:article_snapshot_authors).merge(Postnhost::Snapshot::ArticleAuthor.where(user: author))
    }
    scope :in_category, lambda { |category|
      joins(:article_snapshot_categories).merge(Postnhost::Snapshot::ArticleCategory.where(category:))
    }
    scope :recent_first, -> { order(published_at: :desc) }
    scope :with_language, -> { includes(:language) }
    scope :with_categories, -> { includes(:categories) }
    scope :with_authors, -> { includes(article_snapshot_authors: :user) }

    def self.matching(query)
      return all if query.blank?

      where(
        <<~SQL.squish,
          LOWER(postnhost_article_snapshots.title) LIKE :search OR
          LOWER(postnhost_article_snapshots.content) LIKE :search OR
          LOWER(postnhost_article_snapshots.meta_description) LIKE :search
        SQL
        search: "%#{sanitize_sql_like(query.downcase)}%"
      )
    end

    def published?
      true
    end

    def cover_image
      @cover_image ||= PublishedCoverImage.new(article_id:, identifier: cover_image_identifier)
    end

    def cover_image?
      cover_image.present?
    end

    def differs_from?(draft)
      scalar_changes?(draft) ||
        cover_image_identifier != draft.cover_image.identifier.presence ||
        category_ids.sort != draft.category_ids.sort ||
        snapshot_author_ids != draft.article_authors.order(:position, :id).pluck(:user_id) ||
        snapshot_suggestion_ids != draft.article_suggestions.order(:position, :id).pluck(:suggested_article_id)
    end

    def suggestions_for(language:, limit: MAX_SUGGESTIONS)
      @suggestions_by_language_and_limit ||= {}
      @suggestions_by_language_and_limit[[language.id, limit]] ||= begin
        manual = manual_suggestions(limit:)
        if manual.size >= limit
          preload_suggestion_associations(manual)
        else
          remaining = limit - manual.size
          candidates = automatic_suggestions(language:, exclude_ids: manual.map(&:article_id), limit: remaining * 3)
          suggestions = manual + candidates.sample(remaining, random: Random.new(article_id))
          preload_suggestion_associations(suggestions)
        end
      end
    end

    private

    def scalar_changes?(draft)
      SCALAR_ATTRIBUTES.any? { |attribute| public_send(attribute) != draft.public_send(attribute) }
    end

    def snapshot_author_ids
      article_snapshot_authors.map(&:user_id)
    end

    def snapshot_suggestion_ids
      article_snapshot_suggestions.map(&:suggested_article_id)
    end

    def manual_suggestions(limit:)
      ids = article_snapshot_suggestions.limit(limit).pluck(:suggested_article_id)
      snapshots = self.class.where(article_id: ids).index_by(&:article_id)
      ids.filter_map { |id| snapshots[id] }
    end

    def automatic_suggestions(language:, exclude_ids:, limit:)
      exclusions = [article_id, *exclude_ids]
      category_matches = self.class
                             .joins(:article_snapshot_categories)
                             .where(language:, postnhost_article_snapshot_categories: { category_id: category_ids })
                             .where.not(article_id: exclusions)
                             .distinct
                             .limit(limit)
                             .to_a

      return category_matches if category_matches.size >= limit

      filler = self.class.where(language:)
                   .where.not(article_id: [*exclusions, *category_matches.map(&:article_id)])
                   .limit(limit - category_matches.size)
                   .to_a
      category_matches + filler
    end

    def preload_suggestion_associations(suggestions)
      ActiveRecord::Associations::Preloader.new(
        records: suggestions,
        associations: [:categories, { article_snapshot_authors: :user }]
      ).call
      suggestions
    end
  end
end

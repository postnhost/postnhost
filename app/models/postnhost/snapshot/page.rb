module Postnhost
  class Snapshot::Page < ApplicationRecord
    self.table_name = "postnhost_page_snapshots"

    SCALAR_ATTRIBUTES = %i[language_id title title_tag og_title meta_description content slug].freeze

    belongs_to :page, class_name: "Postnhost::Page"
    belongs_to :language, class_name: "Postnhost::Language"
    belongs_to :paper_trail_version, class_name: "Postnhost::Version"
    # Variant snapshots intentionally survive base unpublishing.
    has_many :page_variant_snapshots, class_name: "Postnhost::Snapshot::PageVariant", primary_key: :page_id,
                                      inverse_of: :page_snapshot, dependent: nil

    validates :title, :content, :slug, :published_at, presence: true
    validates :page_id, :paper_trail_version_id, :slug, uniqueness: true
    validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }

    scope :with_page_and_language, -> { includes(:page, :language) }
    scope :footer_links, -> { where.not(slug: nil).select(:slug, :title).order(:title, :slug) }

    def published?
      true
    end

    def differs_from?(draft)
      SCALAR_ATTRIBUTES.any? { |attribute| public_send(attribute) != draft.public_send(attribute) }
    end

    def title_for_meta
      title_tag.presence || title
    end
  end
end

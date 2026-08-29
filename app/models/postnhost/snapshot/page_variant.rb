module Postnhost
  class Snapshot::PageVariant < ApplicationRecord
    self.table_name = "postnhost_page_variant_snapshots"

    SCALAR_ATTRIBUTES = %i[language_id title title_tag og_title meta_description content].freeze

    belongs_to :page_variant, class_name: "Postnhost::PageVariant"
    belongs_to :page, class_name: "Postnhost::Page"
    belongs_to :page_snapshot, class_name: "Postnhost::Snapshot::Page",
                               foreign_key: :page_id, primary_key: :page_id,
                               inverse_of: :page_variant_snapshots
    belongs_to :language, class_name: "Postnhost::Language"
    belongs_to :paper_trail_version, class_name: "Postnhost::Version"

    validates :title, :content, :published_at, presence: true
    validates :page_variant_id, :paper_trail_version_id, uniqueness: true
    validates :page_id, uniqueness: { scope: :language_id }

    scope :for_language, ->(language) { where(language:) }
    scope :with_language, -> { includes(:language) }

    def self.footer_links_for(language)
      for_language(language)
        .joins(:page_snapshot)
        .merge(Postnhost::Snapshot::Page.where.not(slug: nil))
        .select(
          Postnhost::Snapshot::Page.arel_table[:slug].as("slug"),
          arel_table[:title].as("title")
        )
        .order(arel_table[:title], Postnhost::Snapshot::Page.arel_table[:slug])
    end

    def published?
      true
    end

    def differs_from?(draft)
      SCALAR_ATTRIBUTES.any? { |attribute| public_send(attribute) != draft.public_send(attribute) }
    end
  end
end

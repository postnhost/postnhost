module Postnhost
  class PageVariant < ApplicationRecord
    has_paper_trail versions: { class_name: "Postnhost::Version" },
                    only: %i[title title_tag og_title meta_description content],
                    on: []

    belongs_to :page, counter_cache: true, touch: true
    belongs_to :language
    has_one :user, through: :page
    has_one :page_variant_snapshot, class_name: "Postnhost::Snapshot::PageVariant", dependent: :destroy

    broadcasts_refreshes_to ->(r) { "page_variants_#{r.page_id}" }

    validates :page_id, uniqueness: { scope: :language_id }

    scope :published, -> { joins(:page_variant_snapshot) }

    def published?
      page_variant_snapshot.present?
    end

    def unpublished_changes?
      page_variant_snapshot&.differs_from?(self) || false
    end
  end
end

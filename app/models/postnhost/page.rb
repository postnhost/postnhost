module Postnhost
  class Page < ApplicationRecord
    include PrimaryLanguageGuard
    include Postnhost::Page::ImageUploadable

    has_paper_trail versions: { class_name: "Postnhost::Version" },
                    only: %i[title title_tag og_title meta_description content slug], on: []

    belongs_to :user, class_name: "Postnhost::User"
    belongs_to :language, optional: true

    has_many :page_variants, dependent: :destroy
    has_one :page_snapshot, class_name: "Postnhost::Snapshot::Page", dependent: :destroy
    has_many :page_variant_snapshots, through: :page_variants, source: :page_variant_snapshot

    validates :slug, uniqueness: true,
                     format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" },
                     allow_blank: true
    validate :slug_not_used_by_article, if: -> { slug.present? }

    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
    before_validation :normalize_blank_slug
    scope :published, -> { joins(:page_snapshot) }

    def published?
      page_snapshot.present?
    end

    def unpublished_changes?
      page_snapshot&.differs_from?(self) || false
    end

    def title_for_meta
      title_tag.presence || title
    end

    private

    def normalize_blank_slug
      self.slug = nil if slug.blank?
    end

    def generate_slug
      base_slug = title.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").strip
      self.slug = base_slug
      counter = 1
      while self.class.where(slug: slug).where.not(id: id).exists? || Postnhost::Article.exists?(slug: slug)
        self.slug = "#{base_slug}-#{counter}"
        counter += 1
      end
    end

    def slug_not_used_by_article
      return unless Postnhost::Article.exists?(slug: slug)

      errors.add(:slug, "has already been taken")
    end

    def translation_variants
      page_variants
    end
  end
end

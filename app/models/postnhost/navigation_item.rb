module Postnhost
  class NavigationItem < ApplicationRecord
    self.table_name = "postnhost_navigation_items"

    enum :container_kind, {
      header: 0,
      footer: 1
    }, validate: true

    enum :kind, {
      link: 0,
      dropdown: 1,
      column: 2
    }, validate: true

    enum :target_kind, {
      article: 0,
      page: 1,
      category: 2,
      static_page: 3,
      external: 4,
      text: 5
    }, validate: { allow_nil: true }

    belongs_to :navigation, class_name: "Postnhost::Navigation", inverse_of: :navigation_items
    belongs_to :parent,
               class_name: "Postnhost::NavigationItem",
               optional: true,
               inverse_of: :children
    has_many :children,
             -> { order(:position, :id) },
             class_name: "Postnhost::NavigationItem",
             foreign_key: :parent_id,
             dependent: :destroy,
             inverse_of: :parent

    scope :roots, -> { where(parent_id: nil) }
    scope :with_children, -> { includes(:children) }

    validates :position, numericality: { greater_than_or_equal_to: 0 }

    validate :validate_structure
    validate :validate_target_requirements

    def label_for(locale_key:, default_locale_key:)
      labels = label_translations.deep_stringify_keys
      labels[locale_key.to_s].presence || labels[default_locale_key.to_s].presence
    end

    private

    def validate_structure
      errors.add(:parent_id, "must belong to same navigation") if parent_id.present? && parent&.navigation_id != navigation_id

      if parent_id.blank?
        errors.add(:kind, "must be link or dropdown for header root") if header? && !link? && !dropdown?
        errors.add(:kind, "must be column for footer root") if footer? && !column?
        return
      end

      return if parent.blank?

      if parent.dropdown? && !link?
        errors.add(:kind, "must be link inside dropdown")
      elsif parent.column? && !link?
        errors.add(:kind, "must be link inside column")
      elsif parent.link?
        errors.add(:parent_id, "link items cannot have children")
      end
    end

    def validate_target_requirements
      if dropdown? || column?
        errors.add(:target_kind, "must be blank for grouping items") if target_kind.present?
        errors.add(:target_id, "must be blank for grouping items") if target_id.present?
        errors.add(:target_slug, "must be blank for grouping items") if target_slug.present?
        errors.add(:url, "must be blank for grouping items") if url.present?
        return
      end

      if target_kind.blank?
        errors.add(:target_kind, "is required for link items")
        return
      end

      case target_kind
      when "text"
        errors.add(:target_id, "must be blank for text links") if target_id.present?
        errors.add(:target_slug, "must be blank for text links") if target_slug.present?
        errors.add(:url, "must be blank for text links") if url.present?
      when "external"
        errors.add(:url, "is required") if url.blank?
      when "static_page"
        errors.add(:target_slug, "is required") if target_slug.blank?
      else
        errors.add(:target_id, "is required") if target_id.blank?
      end
    end
  end
end

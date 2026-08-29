module Postnhost
  class Category < ApplicationRecord
    include Postnhost::PublicRevisionTouch

    has_many :article_categories, dependent: :destroy
    has_many :articles, through: :article_categories
    has_many :category_variants, dependent: :destroy
    has_many :article_snapshot_categories, class_name: "Postnhost::Snapshot::ArticleCategory",
                                           dependent: :restrict_with_error
    has_many :article_snapshots, through: :article_snapshot_categories

    scope :with_category_variants_for_language, lambda { |language|
      language&.default? ? all : includes(:category_variants)
    }
    scope :with_published_articles, -> { joins(:article_snapshot_categories).distinct }
    scope :alphabetical, -> { order(:name) }

    validates :name, presence: true, uniqueness: true
    validates :slug, presence: true, uniqueness: true

    after_destroy :touch_articles
    after_save :touch_articles, if: :saved_change_to_name_or_slug?

    private

    def saved_change_to_name_or_slug?
      saved_change_to_name? || saved_change_to_slug?
    end

    def touch_articles
      articles.find_each(&:touch)
    end
  end
end

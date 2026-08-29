module Postnhost
  class Language < ApplicationRecord
    include Postnhost::PublicRevisionTouch

    has_many :articles, dependent: :nullify
    has_many :article_variants, dependent: :destroy
    has_many :category_variants, dependent: :destroy
    has_many :pages, dependent: :nullify
    has_many :page_variants, dependent: :destroy
    has_many :article_snapshots, class_name: "Postnhost::Snapshot::Article", dependent: :restrict_with_error
    has_many :article_variant_snapshots, class_name: "Postnhost::Snapshot::ArticleVariant", dependent: :restrict_with_error
    has_many :page_snapshots, class_name: "Postnhost::Snapshot::Page", dependent: :restrict_with_error
    has_many :page_variant_snapshots, class_name: "Postnhost::Snapshot::PageVariant", dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: true
    validates :html_lang, presence: true, uniqueness: true

    after_destroy :touch_articles_and_variants
    after_save :touch_articles_and_variants, if: :saved_change_to_name_or_html_lang?

    def self.blog_default
      find_by(default: true)
    end

    private

    def saved_change_to_name_or_html_lang?
      saved_change_to_name? || saved_change_to_html_lang?
    end

    def touch_articles_and_variants
      articles.find_each(&:touch)
      article_variants.find_each(&:touch)
      pages.find_each(&:touch)
      page_variants.find_each(&:touch)
    end
  end
end

module Postnhost
  class Article < ApplicationRecord
    include ExcerptOptimizable
    include PrimaryLanguageGuard
    include Postnhost::Article::ImageUploadable

    STATUSES = %w[published draft scheduled].freeze
    SORT_OPTIONS = {
      "created_at_desc" => { column: "created_at", direction: :desc },
      "created_at_asc" => { column: "created_at", direction: :asc }
    }.freeze

    DEFAULT_SORT = "created_at_desc"

    has_paper_trail versions: { class_name: "Postnhost::Version" },
                    only: %i[title title_tag og_title schema_headline schema_article_type meta_description custom_excerpt
                             use_excerpt_as_meta_description content slug cover_image_alt cover_image],
                    on: []

    mount_uploader :cover_image, CoverImageUploader

    belongs_to :user, class_name: "Postnhost::User", optional: true
    belongs_to :language, optional: true, counter_cache: true

    has_many :article_authors, dependent: :destroy
    has_many :authors, -> { order("postnhost_article_authors.position ASC") }, through: :article_authors, source: :user
    has_many :article_categories, dependent: :destroy
    has_many :categories, through: :article_categories
    has_many :article_variants, dependent: :destroy
    has_many :article_suggestions, dependent: :destroy
    has_many :suggested_articles, through: :article_suggestions
    has_one :article_snapshot, class_name: "Postnhost::Snapshot::Article", dependent: :destroy
    has_many :article_variant_snapshots, through: :article_variants, source: :article_variant_snapshot

    validates :slug, uniqueness: true,
                     format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" },
                     allow_blank: true
    validate :slug_not_used_by_page, if: -> { slug.present? }

    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
    before_validation :normalize_blank_slug
    after_create :assign_creator_as_default_author

    scope :published, -> { joins(:article_snapshot) }
    scope :draft, -> { where.missing(:article_snapshot) }
    scope :scheduled, -> { draft.where.not(scheduled_at: nil) }
    scope :top_picks, -> { where(top_pick: true) }
    scope :with_status, lambda { |status|
      case status
      when "published" then published
      when "draft" then draft
      when "scheduled" then scheduled
      else all
      end
    }
    scope :sorted_by, lambda { |sort_key|
      option = SORT_OPTIONS.fetch(sort_key) { SORT_OPTIONS.fetch(DEFAULT_SORT) }
      order(option[:column] => option[:direction])
    }

    def self.normalize_status(status)
      status.to_s.presence_in(STATUSES)
    end

    def self.normalize_sort(sort)
      sort.to_s.presence_in(SORT_OPTIONS.keys) || DEFAULT_SORT
    end

    def published?
      article_snapshot.present?
    end

    def unpublished_changes?
      article_snapshot&.differs_from?(self) || false
    end

    def schedule_publication!(scheduled_time)
      with_lock do
        cancel_scheduled_job
        job = Postnhost::ScheduledArticleJob.set(wait_until: scheduled_time).perform_later(id)
        update!(scheduled_at: scheduled_time, scheduled_job_id: job.job_id)
      end
    end

    def unschedule_publication!
      with_lock do
        cancel_scheduled_job
        update!(scheduled_at: nil, scheduled_job_id: nil)
      end
    end

    def sync_publication_schedule!
      return unless saved_change_to_scheduled_at?

      if scheduled_at.present?
        schedule_publication!(scheduled_at)
      else
        unschedule_publication!
      end
    end

    private

    def normalize_blank_slug
      self.slug = nil if slug.blank?
    end

    def generate_slug
      base_slug = title.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").strip
      self.slug = base_slug
      counter = 1
      while self.class.where(slug: slug).where.not(id: id).exists? || Postnhost::Page.exists?(slug: slug)
        self.slug = "#{base_slug}-#{counter}"
        counter += 1
      end
    end

    def slug_not_used_by_page
      return unless Postnhost::Page.exists?(slug: slug)

      errors.add(:slug, "has already been taken")
    end

    def translation_variants
      article_variants
    end

    def cancel_scheduled_job
      return if scheduled_job_id.blank?
      return unless defined?(SolidQueue::Job)

      SolidQueue::Job.find_by(active_job_id: scheduled_job_id)&.destroy
    end

    def assign_creator_as_default_author
      return if user.blank?
      return if article_authors.exists?(user_id: user_id)

      article_authors.create!(user:, position: article_authors.maximum(:position).to_i + 1)
    end
  end
end

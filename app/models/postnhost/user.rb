module Postnhost
  class User < ApplicationRecord
    include Postnhost::SchemaLocalizable
    include Postnhost::PublicRevisionTouch

    self.table_name = "postnhost_users"

    has_secure_password

    mount_uploader :avatar_file, Postnhost::AvatarUploader

    has_many :articles, class_name: "Postnhost::Article", dependent: :nullify
    has_many :article_authors, class_name: "Postnhost::ArticleAuthor", dependent: :destroy
    has_many :authored_articles, through: :article_authors, source: :article
    has_many :article_snapshot_authors, class_name: "Postnhost::Snapshot::ArticleAuthor",
                                        dependent: :restrict_with_error
    has_many :article_snapshots, through: :article_snapshot_authors
    has_many :pages, class_name: "Postnhost::Page", dependent: :restrict_with_error

    before_validation :normalize_email
    before_validation :normalize_slug
    before_validation :generate_slug_from_name, if: -> { slug.blank? && name.present? }

    validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true,
                     format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }
    validates :password, length: { minimum: 6 }, allow_nil: true

    def schema_profile_hash
      schema_profile.is_a?(Hash) ? schema_profile.deep_stringify_keys : {}
    end

    def schema_profile_value(key, default: nil)
      schema_profile_hash[key.to_s].presence || default
    end

    private

    def normalize_email
      self.email = email.to_s.strip.downcase
    end

    def normalize_slug
      return if slug.nil?

      normalized = slug.to_s.strip.downcase
      normalized = normalized.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").gsub(/\A-|-$/, "")
      self.slug = normalized.presence
    end

    def generate_slug_from_name
      base_slug = name.to_s.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").gsub(/\A-|-$/, "")
      self.slug = base_slug
      counter = 1

      while self.class.where(slug: slug).where.not(id: id).exists?
        self.slug = "#{base_slug}-#{counter}"
        counter += 1
      end
    end
  end
end

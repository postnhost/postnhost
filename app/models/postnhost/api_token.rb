require "digest"
require "securerandom"

module Postnhost
  class ApiToken < ApplicationRecord
    belongs_to :user, class_name: "Postnhost::User"
    validates :name, :token_digest, presence: true
    validates :token_digest, uniqueness: true

    def self.issue!(user:, name:)
      secret = "pnh_#{SecureRandom.urlsafe_base64(32)}"
      token = create!(user:, name:, token_digest: Digest::SHA256.hexdigest(secret))
      [token, secret]
    end

    def self.authenticate(secret)
      return if secret.blank?

      find_by(token_digest: Digest::SHA256.hexdigest(secret), revoked_at: nil)
    end

    def revoke!
      update!(revoked_at: Time.current)
    end
  end
end

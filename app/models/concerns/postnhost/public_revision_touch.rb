module Postnhost
  module PublicRevisionTouch
    extend ActiveSupport::Concern

    included do
      after_commit :bump_public_site_revision
    end

    private

    def bump_public_site_revision
      Postnhost::PublicSiteRevision.bump!
    end
  end
end

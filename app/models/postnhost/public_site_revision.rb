module Postnhost
  class PublicSiteRevision < ApplicationRecord
    SINGLETON_ID = 1

    def self.current
      find_or_create_by!(id: SINGLETON_ID)
    end

    def self.locked
      current
      lock.find(SINGLETON_ID)
    end

    def self.bump!
      transaction do
        locked.bump!
      end
    end

    def bump!
      update!(revision: revision + 1)
    end
  end
end

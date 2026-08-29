module Postnhost
  class Template < ApplicationRecord
    include Postnhost::PublicRevisionTouch

    self.table_name = "postnhost_templates"

    DEFAULT_NAME = "default"
    NAMES = [DEFAULT_NAME, "swiss-editorial", "workspace-journal"].freeze

    validates :name, inclusion: { in: NAMES }

    def self.current
      first_or_create!(name: DEFAULT_NAME)
    end

    def self.active_name
      current.name
    end
  end
end

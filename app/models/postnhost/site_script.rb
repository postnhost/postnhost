module Postnhost
  class SiteScript < ApplicationRecord
    self.table_name = "postnhost_site_scripts"

    PLACEMENTS = %w[head body_start body_end].freeze

    belongs_to :setting, class_name: "Postnhost::Setting", touch: true

    validates :placement, inclusion: { in: PLACEMENTS }
  end
end

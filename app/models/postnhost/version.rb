module Postnhost
  class Version < ApplicationRecord
    include PaperTrail::VersionConcern

    self.table_name = "postnhost_versions"
  end
end

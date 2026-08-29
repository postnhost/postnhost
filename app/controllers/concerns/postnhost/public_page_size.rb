module Postnhost
  module PublicPageSize
    extend ActiveSupport::Concern

    PAGINATION_SLOTS = 3

    private

    def pagination_slots
      PAGINATION_SLOTS
    end

    def public_page_size
      current_setting.effective_public_page_size
    end
  end
end

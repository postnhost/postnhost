module Postnhost
  # Used only by Management::Preview for an authenticated in-process render.
  # There are no routes to this controller.
  class ManagementPreviewController < Public::ArticlesController
    private

    def current_user
      request.env.fetch("postnhost.management_user")
    end
  end
end

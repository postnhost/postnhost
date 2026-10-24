module Postnhost
  # Used only by Management::Preview for an authenticated in-process render.
  # There are no routes to this controller.
  class ManagementPreviewController < Public::ArticlesController
    helper_method :postnhost

    private

    def postnhost
      @postnhost ||= ActionDispatch::Routing::RoutesProxy.new(Engine.routes, self, Engine.routes.url_helpers)
    end

    def current_user
      request.env.fetch("postnhost.management_user")
    end
  end
end

module Postnhost
  module PublicHttpCaching
    extend ActiveSupport::Concern

    included do
      helper_method :public_site_revision
    end

    private

    def apply_public_http_cache(*dependencies, template:)
      return if user_signed_in?

      fresh_when(
        etag: [public_layout_digest, public_site_revision, @current_language&.id, controller_path, action_name,
               request.script_name, current_setting.site_configuration_cache_key, *dependencies].compact,
        public: true,
        template:
      )
      expires_in 0.seconds, public: true, must_revalidate: true
    end

    def public_site_revision
      public_request_context.public_site_revision
    end

    def public_layout_digest
      ActionView::Digestor.digest(
        name: "layouts/#{resolved_public_layout_template}",
        format: nil,
        finder: lookup_context
      )
    end
  end
end

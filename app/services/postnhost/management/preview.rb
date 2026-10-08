module Postnhost
  module Management
    module Preview
      def self.call(user:, record: nil, template: nil, script_name: "")
        action = record ? "preview" : "index"
        path = record ? "/preview/#{record.id}" : "/?preview_template=#{template}"
        origin = Setting.current.effective_site_url || "http://example.com"
        env = Rack::MockRequest.env_for("#{origin}#{script_name}#{path}")
        env["SCRIPT_NAME"] = script_name
        env["PATH_INFO"] = path.split("?").first
        env["postnhost.management_user"] = user
        env["action_dispatch.request.path_parameters"] = { controller: "postnhost/management_preview", action:, id: record&.id }
        env["action_dispatch.routes"] = Engine.routes
        status, _headers, body = I18n.with_locale(I18n.default_locale) { ManagementPreviewController.action(action).call(env) }
        html = +""
        body.each { |chunk| html << chunk }
        raise ArgumentError, "Preview could not be rendered" unless status == 200

        { html:, template: template || Template.active_name }
      ensure
        body&.close if body.respond_to?(:close)
      end
    end
  end
end

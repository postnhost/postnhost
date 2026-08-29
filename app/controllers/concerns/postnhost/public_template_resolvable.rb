module Postnhost
  module PublicTemplateResolvable
    extend ActiveSupport::Concern

    included do
      helper_method :current_public_template_name
    end

    def default_url_options
      options = @public_default_url_options ||= super.merge(current_setting.site_url_options)
      return options unless preview_public_template_name

      options.merge(preview_template: preview_public_template_name)
    end

    private

    def current_public_template_name
      @current_public_template_name ||= preview_public_template_name || public_request_context.template_name
    end

    def preview_public_template_name
      return @preview_public_template_name if defined?(@preview_public_template_name)
      return @preview_public_template_name = nil unless user_signed_in? && params[:preview_template].present?

      @preview_public_template_name = params[:preview_template].tap do |template_name|
        raise ActiveRecord::RecordNotFound unless Postnhost::Template::NAMES.include?(template_name)
      end
    end

    def resolved_public_layout_template
      "postnhost/public/templates/#{current_public_template_name}"
    end

    def render_public_template(path, **options)
      resolved_template = resolve_public_template(path)
      render({ template: resolved_template }.merge(options))
    end

    def resolve_public_template(path)
      "postnhost/public/templates/#{current_public_template_name}/#{path}"
    end
  end
end

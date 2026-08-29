module Postnhost
  class Public::StaticPagesController < Postnhost::PublicController
    include LanguageSwitcher
    include PublicFooterData
    include PublicHttpCaching
    include PublicTemplateResolvable

    layout :resolved_public_layout_template

    def show
      raise ActionController::RoutingError, "Not Found" unless valid_slug?

      if page_resolution.present?
        apply_public_http_cache(page_resolution.record_id, template: resolve_public_template("static_pages/show"))
        return if performed?

        set_footer_data
        load_dynamic_page
        return render_public_template("static_pages/show")
      end

      template = resolved_template
      raise ActionController::RoutingError, "Not Found" unless template

      apply_public_http_cache(params[:slug], template:)
      return if performed?

      set_footer_data
      render template: template
    end

    private

    def resolved_template
      template_path = "postnhost/static_pages/#{params[:slug]}"
      template_path if lookup_context.exists?(template_path, [], false)
    end

    def page_resolution
      return @page_resolution if defined?(@page_resolution)

      @page_resolution = public_request_context.resolve_kind(:page, params[:slug])
    end

    def load_dynamic_page
      @page = page_snapshot
      @available_variants = @page.page_variant_snapshots.with_language

      if localized_request?
        @content = dynamic_page_variant
        @actual_language = dynamic_page_variant.language
      else
        @content = page_snapshot
        @actual_language = page_snapshot.language || @current_language
      end
    end

    def page_snapshot
      return @page_snapshot if defined?(@page_snapshot)

      @page_snapshot = page_resolution.record
      ActiveRecord::Associations::Preloader.new(records: [@page_snapshot], associations: %i[page language]).call
      @page_snapshot
    end

    def dynamic_page_variant
      return @dynamic_page_variant if defined?(@dynamic_page_variant)
      return @dynamic_page_variant = nil if page_snapshot.blank?

      @dynamic_page_variant = page_snapshot.page_variant_snapshots.for_language(@current_language).first
    end

    def valid_slug?
      params[:slug].to_s.match?(/\A[a-z0-9_-]+\z/)
    end
  end
end

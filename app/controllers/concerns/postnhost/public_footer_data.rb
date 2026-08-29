module Postnhost
  module PublicFooterData
    extend ActiveSupport::Concern

    private

    def set_footer_data
      @setting = current_setting
      @use_auto_header_navigation = @setting.use_auto_header_navigation
      @use_auto_footer_navigation = @setting.use_auto_footer_navigation
      initialize_navigation_data

      set_auto_navigation_data if @use_auto_header_navigation || @use_auto_footer_navigation
      set_custom_navigation_data unless @use_auto_header_navigation && @use_auto_footer_navigation
    end

    def initialize_navigation_data
      @sidebar_categories = []
      @header_categories = []
      @footer_categories = []
      @footer_published_pages = []
      @footer_static_pages = []
      @header_navigation_items = []
      @footer_navigation_columns = []
    end

    def set_auto_navigation_data
      data = Rails.cache.fetch(public_navigation_cache_key("auto")) do
        {
          categories: auto_navigation_categories.to_a,
          published_pages: published_footer_pages.to_a
        }
      end

      if @use_auto_header_navigation
        @sidebar_categories = data.fetch(:categories)
        @header_categories = data.fetch(:categories)
      end

      return unless @use_auto_footer_navigation

      @footer_categories = data.fetch(:categories)
      @footer_published_pages = data.fetch(:published_pages)
      @footer_static_pages = static_footer_pages - @footer_published_pages.map(&:slug)
    end

    def set_custom_navigation_data
      items = Rails.cache.fetch(public_navigation_cache_key("custom")) do
        @setting.current_navigation.navigation_items.roots.with_children.to_a
      end
      @default_language = public_request_context.default_language
      targets = Postnhost::PublicNavigationTargets.call(
        items: items.flat_map { |item| [item, *item.children] },
        language: @current_language
      ).value
      @navigation_target_cache = targets.records
      @navigation_variant_cache = targets.variants

      @header_navigation_items = items.select { |item| item.container_kind == "header" && item.parent_id.nil? }.sort_by(&:position) unless @use_auto_header_navigation
      return if @use_auto_footer_navigation

      @footer_navigation_columns = items.select { |item| item.container_kind == "footer" && item.parent_id.nil? }.sort_by(&:position)
    end

    def public_navigation_cache_key(kind)
      ["postnhost", "public_navigation", kind, public_site_revision, @current_language]
    end

    def auto_navigation_categories
      Postnhost::Category.with_category_variants_for_language(@current_language)
                         .with_published_articles
                         .alphabetical
    end

    def static_footer_pages
      static_page_template_paths
        .map { |template_path| File.basename(template_path, ".html.erb") }
        .uniq
        .sort
    end

    def published_footer_pages
      return default_footer_pages if @current_language.default?

      localized_footer_pages
    end

    def default_footer_pages
      Postnhost::Snapshot::Page.footer_links
    end

    def localized_footer_pages
      Postnhost::Snapshot::PageVariant.footer_links_for(@current_language)
    end

    def static_page_template_paths
      [
        Rails.root.join("app/views/postnhost/static_pages/*.html.erb"),
        Postnhost::Engine.root.join("app/views/postnhost/static_pages/*.html.erb")
      ].flat_map { |pattern| Dir[pattern.to_s] }
    end
  end
end

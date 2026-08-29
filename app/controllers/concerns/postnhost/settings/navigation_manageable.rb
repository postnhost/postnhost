module Postnhost
  module Settings
    module NavigationManageable
      extend ActiveSupport::Concern

      private

      def set_navigation_editor_state
        @navigation_locale_keys = Postnhost::Language.order(:name).pluck(:html_lang)
        @selected_navigation_locale_key = selected_navigation_locale_key
        @default_navigation_locale_key = Postnhost::Language.blog_default&.html_lang || I18n.default_locale.to_s
        @navigation = @setting.current_navigation
        @navigation_tree = navigation_tree_for_editor
        @navigation_target_options = navigation_target_options
      end

      def selected_navigation_locale_key
        locale_keys = @navigation_locale_keys || Postnhost::Language.order(:name).pluck(:html_lang)
        locale = params[:locale].presence || params[:locale_key].presence
        locale = locale.to_s if locale.present?
        return locale if locale.present? && locale_keys.include?(locale)

        locale_keys.first
      end

      def update_navigation
        set_navigation_editor_state
        @setting.assign_attributes(
          use_auto_header_navigation: navigation_setting_enabled?(:use_auto_header_navigation),
          use_auto_footer_navigation: navigation_setting_enabled?(:use_auto_footer_navigation)
        )

        tree = parse_navigation_tree
        if tree.nil?
          @setting.errors.add(:base, "Navigation payload is invalid")
          render :edit, status: :unprocessable_content
          return
        end

        Postnhost::Setting.transaction do
          @setting.save!
          @navigation.replace_tree!(tree:, locale_key: @selected_navigation_locale_key)
        end

        redirect_to edit_settings_path(section: "navigation", locale: @selected_navigation_locale_key),
                    notice: "Navigation settings were successfully updated."
      end

      def navigation_setting_enabled?(key)
        ActiveModel::Type::Boolean.new.cast(params.dig(:setting, key))
      end

      def parse_navigation_tree
        raw_tree = params.dig(:navigation, :tree)
        return nil if raw_tree.blank?

        parsed = JSON.parse(raw_tree)
        return unless parsed.is_a?(Hash)

        header = parsed["header"]
        footer = parsed["footer"]
        return unless header.is_a?(Array) && footer.is_a?(Array)

        {
          "header" => header,
          "footer" => footer
        }
      rescue JSON::ParserError
        nil
      end

      def navigation_tree_for_editor
        items = @navigation.navigation_items.includes(:children).to_a

        {
          "header" => navigation_items_tree(items.select { |item| item.container_kind == "header" && item.parent_id.nil? }),
          "footer" => navigation_items_tree(items.select { |item| item.container_kind == "footer" && item.parent_id.nil? })
        }
      end

      def navigation_items_tree(items)
        items.sort_by(&:position).map do |item|
          {
            "id" => item.id,
            "kind" => item.kind,
            "target_kind" => item.target_kind,
            "target_id" => item.target_id,
            "target_slug" => item.target_slug,
            "url" => item.url,
            "nofollow" => item.nofollow,
            "label" => item.label_for(locale_key: @selected_navigation_locale_key, default_locale_key: @default_navigation_locale_key),
            "has_locale_override" => item.label_translations.to_h.key?(@selected_navigation_locale_key),
            "children" => navigation_items_tree(item.children)
          }
        end
      end

      def navigation_target_options
        {
          "article" => Postnhost::Snapshot::Article.order(:title).pluck(:title, :article_id),
          "page" => Postnhost::Snapshot::Page.order(:title).pluck(:title, :page_id),
          "category" => Postnhost::Category.order(:name).pluck(:name, :id),
          "static_page" => static_page_slugs.map { |slug| [slug.humanize, slug] }
        }
      end

      def static_page_slugs
        [
          Rails.root.join("app/views/postnhost/static_pages/*.html.erb"),
          Postnhost::Engine.root.join("app/views/postnhost/static_pages/*.html.erb")
        ].flat_map { |pattern| Dir[pattern.to_s] }
         .map { |path| File.basename(path, ".html.erb") }
         .uniq
         .sort
      end
    end
  end
end

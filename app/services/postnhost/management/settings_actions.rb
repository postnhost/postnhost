module Postnhost
  module Management
    class SettingsActions < BaseService
      include Postnhost::Settings::NavigationManageable

      def initialize(action:, record:, arguments:)
        @action = action
        @record = record
        @arguments = arguments
      end

      def call
        return upload if action.start_with?("upload_")

        if %w[remove_logo remove_og_image].include?(action)
          field = action == "remove_logo" ? :site_logo : :og_image
          record.update!(field => nil)
          return record
        end

        validate_locale!
        case action
        when "get_navigation"
          @setting = record
          @selected_navigation_locale_key = arguments.fetch("locale")
          @default_navigation_locale_key = Language.blog_default&.html_lang || I18n.default_locale.to_s
          @navigation = record.current_navigation
          { tree: navigation_tree_for_editor, targets: navigation_target_options }
        when "replace_navigation"
          tree = arguments.fetch("tree")
          record.current_navigation.replace_tree!(tree:, locale_key: arguments.fetch("locale"))
          { navigation: record.current_navigation.navigation_items.to_a }
        when "get_translations"
          Settings::I18nOverrides.editable_translations_for_locale(arguments.fetch("locale"), record.locale_overrides)
        when "update_translations"
          overrides = Settings::I18nOverrides.merge_locale_overrides(record.locale_overrides, arguments.fetch("locale"), arguments.fetch("translations"))
          record.update!(locale_overrides: overrides)
          record
        else
          raise ArgumentError, "Unsupported action"
        end
      end

      private

      attr_reader :action, :record, :arguments

      def validate_locale!
        raise ArgumentError, "Locale must belong to a configured language" unless Language.exists?(html_lang: arguments["locale"])
      end

      def upload
        file = Upload.open(arguments.fetch("file"))
        if action == "upload_image"
          result = record.upload_inline_image(file)
          return result[:success] ? success({ url: result[:url] }) : failure(result[:error])
        end
        field = { "upload_cover" => :cover_image, "upload_avatar" => :avatar_file, "upload_logo" => :site_logo, "upload_og_image" => :og_image }.fetch(action)
        record.update!(field => file)
        { url: record.public_send(field).url }
      end
    end
  end
end

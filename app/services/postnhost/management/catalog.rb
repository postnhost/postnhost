module Postnhost
  module Management
    module Catalog
      INTEGER = { type: "integer", minimum: 1 }.freeze
      IDS = { type: "array", items: INTEGER, minItems: 1, maxItems: 100, uniqueItems: true }.freeze
      FILE = { type: "object", properties: { filename: { type: "string" }, content_type: { type: "string" }, base64: { type: "string" } }, required: %w[filename content_type base64], additionalProperties: false }.freeze
      READ_ACTIONS = %w[list get versions version_preview preview get_navigation get_translations].freeze

      def self.tools
        @tools ||= freeze_schema(build_tools)
      end

      def self.build_tools
        Resources::DEFINITIONS.flat_map do |resource, definition|
          actions = definition[:singleton] ? %w[get update] : %w[list get create update delete]
          actions.delete("update") if resource == "api_tokens"
          actions += %w[publish unpublish] if %w[articles pages article_variants page_variants].include?(resource)
          actions += %w[translate] if %w[articles pages categories].include?(resource)
          actions += %w[bulk_publish bulk_unpublish bulk_delete] if %w[article_variants page_variants].include?(resource)
          actions += %w[versions version_preview restore preview upload_image upload_cover remove_cover] if resource == "articles"
          actions += %w[preview upload_image] if resource == "pages"
          actions += %w[get_navigation replace_navigation get_translations update_translations upload_logo upload_og_image remove_logo remove_og_image] if resource == "settings"
          actions += %w[preview] if resource == "template"
          actions += %w[upload_avatar] if resource == "users"
          actions.map { |action| tool(resource, action, definition) }
        end
      end

      def self.fetch(name)
        @tools_by_name ||= tools.index_by { |tool| tool[:name] }.freeze
        @tools_by_name.fetch(name) { raise ArgumentError, "Unknown command: #{name}" }
      end

      def self.tool(resource, action, definition)
        read = READ_ACTIONS.include?(action)
        detail = if action == "list"
                   "Returns compact summaries; use get for full content, relationships and draft comparisons."
                 elsif read
                   "Reads CMS draft data."
                 else
                   "Uses CMS validations and publication workflows."
                 end
        { name: "#{resource}_#{action}", description: "#{action.tr('_', ' ').capitalize} #{resource.tr('_', ' ')}. #{detail}",
          inputSchema: schema(resource, action, definition),
          annotations: { readOnlyHint: read, destructiveHint: !read, idempotentHint: read || %w[update unpublish delete].include?(action) || action.start_with?("remove_"), openWorldHint: action == "translate" } }
      end

      def self.schema(resource, action, definition)
        properties = {}
        required = []
        if definition[:parent]
          properties["parent_id"] = INTEGER
          required << "parent_id"
        end
        unless definition[:singleton] || %w[list create translate].include?(action) || action.start_with?("bulk_")
          properties["id"] = INTEGER
          required << "id"
        end
        case action
        when "list"
          properties["page"] = INTEGER
          properties["limit"] = { type: "integer", minimum: 1, maximum: 100 }
          properties["language_id"] = INTEGER if definition[:fields].include?("language_id")
          properties.merge!("status" => { type: "string", enum: Article::STATUSES }, "sort" => { type: "string", enum: Article::SORT_OPTIONS.keys }, "mine" => { type: "boolean" }, "category_id" => INTEGER, "user_id" => INTEGER) if resource == "articles"
        when "preview"
          properties["name"] = { type: "string", enum: Template::NAMES } if resource == "template"
          required << "name" if resource == "template"
        when "create", "update"
          properties["attributes"] = { type: "object", properties: definition[:fields].index_with { |field| field_schema(field, resource) }, additionalProperties: false }
          required << "attributes"
        when "translate"
          properties["id"] = INTEGER
          properties["language_ids"] = IDS
          required += %w[id language_ids]
        when "bulk_publish", "bulk_unpublish", "bulk_delete"
          properties["ids"] = IDS
          required << "ids"
        when "restore", "version_preview"
          properties["version_id"] = INTEGER
          required << "version_id"
        when "replace_navigation"
          properties["tree"] = { type: "object", properties: { header: { type: "array", items: navigation_item_schema, maxItems: 100 }, footer: { type: "array", items: navigation_item_schema, maxItems: 100 } }, required: %w[header footer], additionalProperties: false }
          required << "tree"
          properties["locale"] = { type: "string" }
          required << "locale"
        when "get_navigation", "get_translations", "update_translations"
          properties["locale"] = { type: "string" }
          required << "locale"
          if action == "update_translations"
            properties["translations"] = { type: "object", additionalProperties: { type: "string" } }
            required << "translations"
          end
        else
          if action.start_with?("upload_")
            properties["file"] = FILE
            required << "file"
          end
        end
        { type: "object", properties:, required:, additionalProperties: false }
      end

      def self.navigation_item_schema(depth = 0)
        properties = {
          id: INTEGER, kind: { type: "string", enum: NavigationItem.kinds.keys },
          target_kind: { type: %w[string null], enum: NavigationItem.target_kinds.keys + [nil] },
          target_id: { type: %w[integer null] }, target_slug: { type: %w[string null] },
          url: { type: %w[string null] }, label: { type: %w[string null] }, nofollow: { type: "boolean" }
        }
        properties[:children] = { type: "array", items: navigation_item_schema(depth + 1), maxItems: 100 } if depth < 2
        { type: "object", properties:, required: ["kind"], additionalProperties: false }
      end

      # This module is reloadable: schemas and their name index disappear with it.
      # Freeze nested values so one consumer cannot modify another client's contract.
      def self.freeze_schema(value)
        case value
        when Hash then value.each do |key, child|
          freeze_schema(key)
          freeze_schema(child)
        end
        when Array then value.each { |child| freeze_schema(child) }
        end
        value.freeze
      end
      private_class_method :build_tools, :freeze_schema

      def self.field_schema(field, resource)
        return { type: "string", enum: Template::NAMES } if resource == "template" && field == "name"
        return { type: "string", enum: SiteScript::PLACEMENTS } if field == "placement"

        return { type: %w[string null], format: "date-time" } if field == "scheduled_at"

        if field.end_with?("_ids")
          { type: "array", items: INTEGER, maxItems: 100, uniqueItems: true }
        elsif field.end_with?("_id") || field == "public_page_size"
          { type: %w[integer null] }
        elsif %w[default top_pick use_excerpt_as_meta_description author_pages_enabled search_enabled show_powered_by use_auto_header_navigation use_auto_footer_navigation].include?(field)
          { type: "boolean" }
        elsif field == "schema_settings"
          SchemaFields.settings
        elsif field == "schema_profile"
          SchemaFields.profile
        elsif field == "schema_locale_overrides"
          SchemaFields.overrides(resource)
        else
          { type: %w[string null] }
        end
      end
    end
  end
end

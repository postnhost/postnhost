module Postnhost
  module Management
    class Command < BaseService
      def initialize(name:, arguments:, user:, script_name: "")
        @name = name
        @arguments = arguments.deep_stringify_keys
        @user = user
        @script_name = script_name
      end

      def call
        return failure("Authentication required", status: :unauthorized) unless user

        tool = Catalog.fetch(name)
        Input.validate!(arguments, tool[:inputSchema])
        resource = Resources::DEFINITIONS.keys.find { |key| name.start_with?("#{key}_") }
        action = name.delete_prefix("#{resource}_")
        result = PaperTrail.request(whodunnit: user.id.to_s) do
          Time.use_zone(Setting.current.effective_timezone_name) { execute(resource, action) }
        end
        result.is_a?(ServiceResult) ? serialize_result(result) : success(Serializer.call(result), status: :ok)
      rescue ActiveRecord::RecordNotFound
        failure("Record not found", status: :not_found)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
        failure(e.record.errors.full_messages)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey
        failure("Record conflicts with existing or referenced data", status: :conflict)
      rescue ActiveRecord::StaleObjectError
        failure("Record changed; reload and retry", status: :conflict)
      rescue ArgumentError, TypeError => e
        failure(e.message, status: :bad_request)
      end

      private

      attr_reader :name, :arguments, :user, :script_name

      def serialize_result(result)
        ServiceResult.new(value: Serializer.call(result.value), errors: result.errors, status: result.status || :ok)
      end

      def execute(resource, action)
        definition = Resources::DEFINITIONS.fetch(resource)
        scope = scope_for(resource, definition)
        return list(scope, resource) if action == "list"
        return create(scope, resource, definition) if action == "create"
        return ContentActions.call(resource:, action:, scope:, arguments:) if action.start_with?("bulk_")

        scope = scope.select(:id) if action == "versions"
        record = definition[:singleton] ? Resources.model(resource).current : scope.find(arguments.fetch("id"))
        case action
        when "get" then record
        when "update" then update(record)
        when "delete" then delete(record)
        when "preview"
          if resource == "template"
            Preview.call(user:, template: arguments.fetch("name"), script_name:)
          elsif resource == "articles"
            Preview.call(user:, record:, script_name:).merge(draft: record)
          else
            ContentActions.call(resource:, action:, scope:, record:, arguments:)
          end
        else ContentActions.call(resource:, action:, scope:, record:, arguments:)
        end
      end

      def scope_for(resource, definition)
        if definition[:parent]
          parent = Resources.model(definition[:parent]).find(arguments.fetch("parent_id"))
          parent.public_send(resource)
        elsif resource == "api_tokens"
          user.api_tokens
        elsif resource == "site_scripts"
          Setting.current.site_scripts
        else
          Resources.model(resource).all
        end
      end

      def list(scope, resource)
        scope = scope.where(language_id: arguments["language_id"]) if arguments["language_id"] && scope.klass.column_names.include?("language_id")
        if resource == "articles"
          scope = scope.where(user_id: user.id) if arguments["mine"]
          scope = scope.joins(:article_categories).where(postnhost_article_categories: { category_id: arguments["category_id"] }) if arguments["category_id"]
          scope = scope.where(user_id: arguments["user_id"]) if arguments["user_id"]
          scope = scope.with_status(arguments["status"]).sorted_by(arguments["sort"])
        else
          scope = scope.order(:id)
        end
        limit = arguments.fetch("limit", 25)
        page = arguments.fetch("page", 1)
        records = summary_scope(scope, resource).limit(limit).offset((page - 1) * limit)
        result = { records: records.map { |record| Serializer.summary(record) }, total: scope.count, page:, limit: }
        result[:static_pages] = static_page_slugs if resource == "pages"
        result
      end

      def summary_scope(scope, resource)
        table = scope.klass.arel_table
        fields = Serializer::SUMMARY_FIELDS & scope.klass.column_names
        records = scope.select(*fields.map { |field| table[field] })
        snapshot = Resources::DEFINITIONS.fetch(resource)[:snapshot]
        return records unless snapshot

        association = scope.klass.reflect_on_association(snapshot)
        snapshot_table = association.klass.arel_table
        snapshot_id = association.klass.where(snapshot_table[association.foreign_key].eq(table[:id])).select(:id).limit(1)
        records.select(snapshot_id.arel.as("management_snapshot_id"))
      end

      def static_page_slugs
        [Rails.root, Engine.root].flat_map { |root| Dir[root.join("app/views/postnhost/static_pages/*.html.erb").to_s] }
                                 .map { |path| File.basename(path, ".html.erb") }.uniq.sort
      end

      def create(scope, resource, definition)
        attrs = arguments.fetch("attributes")
        if resource == "api_tokens"
          token, secret = ApiToken.issue!(user:, **attrs.symbolize_keys)
          return { token:, secret: }
        end
        if %w[articles pages].include?(resource)
          attrs = { "language_id" => Language.blog_default&.id }.merge(attrs).merge("user_id" => user.id)
        elsif definition[:parent] && resource != "category_variants"
          parent = Resources.model(definition[:parent]).find(arguments.fetch("parent_id"))
          copied = parent.attributes.slice(*definition[:fields]).except("language_id")
          attrs = copied.merge(attrs)
        end
        validate_schema_locales!(attrs)
        record = scope.create!(attrs)
        record.sync_publication_schedule! if record.is_a?(Article)
        record
      end

      def update(record)
        raise ArgumentError, "Translation is still generating" if record.respond_to?(:generating?) && record.generating?

        attrs = arguments.fetch("attributes")
        attrs = attrs.except("password", "password_confirmation") if record.is_a?(User) && attrs["password"].blank?
        validate_schema_locales!(attrs)
        record.update!(attrs)
        record.sync_publication_schedule! if record.is_a?(Article)
        record
      end

      def validate_schema_locales!(attributes)
        return unless attributes["schema_locale_overrides"]

        unknown = attributes["schema_locale_overrides"].keys - Language.pluck(:html_lang)
        raise ArgumentError, "Schema locales must belong to configured languages" if unknown.any?
      end

      def delete(record)
        if record.is_a?(ApiToken)
          record.revoke!
          return { revoked: true, id: record.id }
        end
        if record.is_a?(User)
          return failure("You cannot remove your own account", status: :conflict) if record == user
          return failure("Author owns pages; reassign or remove them first", status: :conflict) if record.pages.exists?

          User.transaction do
            Article.where(user_id: record.id).update_all(user_id: nil, updated_at: Time.current)
            record.article_authors.delete_all
            record.destroy!
          end
        else
          record.destroy!
        end
        { deleted: true, id: record.id }
      end
    end
  end
end

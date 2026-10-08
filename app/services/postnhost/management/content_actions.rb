module Postnhost
  module Management
    class ContentActions < BaseService
      def initialize(resource:, action:, scope:, arguments:, record: nil)
        @resource = resource
        @action = action
        @scope = scope
        @arguments = arguments
        @record = record
      end

      def call
        case action
        when "publish", "unpublish" then transition
        when "bulk_publish", "bulk_unpublish" then bulk_transition
        when "bulk_delete" then bulk_delete
        when "translate" then Translation::Enqueue.call(record:, language_ids: arguments.fetch("language_ids"))
        when "versions" then versions
        when "version_preview" then record.versions.find(arguments.fetch("version_id")).reify
        when "restore" then Publishing::Versions::RestoreDraft.call(record:, version: record.versions.find(arguments.fetch("version_id")))
        when "preview" then { draft: record, html: record.content }
        when "remove_cover"
          record.update_column(:cover_image, nil)
          record.reload
        else
          SettingsActions.call(action:, record:, arguments:)
        end
      end

      private

      attr_reader :resource, :action, :scope, :arguments, :record

      def versions
        columns = record.versions.klass.column_names - ["object"]
        record.versions.select(*columns).order(id: :desc).map(&:attributes)
      end

      def transition
        return failure("Translation is still generating", status: :conflict) if record.respond_to?(:generating?) && record.generating?

        service = publishing_module.const_get(action.classify, false)
        result = service.call(resource.singularize.to_sym => record)
        result.success? ? success(record.reload, status: result.status) : result
      end

      def bulk_transition
        parent_resource = Resources::DEFINITIONS.fetch(resource).fetch(:parent)
        parent = Resources.model(parent_resource).find(arguments.fetch("parent_id"))
        service = publishing_module.const_get("#{action.delete_prefix('bulk_').classify}Many", false)
        service.call(parent_resource.singularize.to_sym => parent, ids: arguments.fetch("ids"))
      end

      def publishing_module
        Publishing.const_get(resource.camelize, false)
      end

      def bulk_delete
        records = scope.where(id: arguments.fetch("ids")).order(:id)
        failures = (arguments.fetch("ids") - records.pluck(:id)).index_with { ["Translation not found"] }
        deleted = []
        records.each do |variant|
          if variant.generating?
            failures[variant.id] = ["Translation is still generating"]
          elsif variant.destroy
            deleted << variant.id
          else
            failures[variant.id] = variant.errors.full_messages
          end
        end
        success({ deleted:, failures: }, status: failures.empty? ? :ok : :unprocessable_content)
      end
    end
  end
end

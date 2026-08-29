module Postnhost
  module Publishing
    class BulkTransition < BaseService
      def initialize(scope:, ids:, service_class:, argument_name:)
        @scope = scope
        @ids = ids
        @service_class = service_class
        @argument_name = argument_name
      end

      def call
        normalized_ids = normalize_ids
        return failure("Select at least one translation") if normalized_ids.empty?

        records = scope.where(id: normalized_ids).order(:id).to_a
        successes, failures = transition_all(records)
        (normalized_ids - records.map(&:id)).each { |id| failures[id] = ["Translation was not found"] }

        success({ successes:, failures: }, status: failures.empty? ? :ok : :unprocessable_content)
      rescue ArgumentError, TypeError
        failure("Translation IDs must be integers")
      end

      private

      attr_reader :scope, :ids, :service_class, :argument_name

      def transition_all(records)
        successes = []
        failures = {}
        return [successes, failures] if records.empty?

        Revision.hold do
          records.each do |record|
            result = transition(record)
            if result.success?
              successes << record
            else
              failures[record.id] = result.errors
            end
          end
        end

        [successes, failures]
      end

      # The batch shares one revision lock, so each record needs its own savepoint to keep a
      # partial write from a failed record out of the records that succeeded.
      def transition(record)
        result = nil
        ApplicationRecord.transaction(requires_new: true) do
          result = service_class.call(argument_name => record)
          raise ActiveRecord::Rollback unless result.success?
        end
        result
      end

      def normalize_ids
        Array(ids).compact_blank.map { |id| id.is_a?(Integer) ? id : Integer(id, 10) }.uniq.sort
      end
    end
  end
end

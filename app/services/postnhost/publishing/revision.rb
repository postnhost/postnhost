module Postnhost
  module Publishing
    # Serializes publication transitions on the singleton public site revision row.
    #
    # The outermost hold owns the transaction, the row lock, and a single revision bump.
    # Nested holds join it, so a bulk transition locks once and publishes as one public change
    # instead of invalidating public caches per record.
    class Revision
      STATE_KEY = :postnhost_publishing_revision

      def self.hold
        return yield if held

        ApplicationRecord.transaction do
          self.held = PublicSiteRevision.locked
          begin
            result = yield
            held.bump!
            result
          ensure
            self.held = nil
          end
        end
      end

      def self.held
        ActiveSupport::IsolatedExecutionState[STATE_KEY]
      end

      def self.held=(revision)
        ActiveSupport::IsolatedExecutionState[STATE_KEY] = revision
      end

      private_class_method :held=
    end
  end
end

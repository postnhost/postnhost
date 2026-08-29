module Postnhost
  module Publishing
    class Pages::Publish < BaseService
      def initialize(page:)
        @page = page
      end

      def call
        snapshot = Revision.hold do
          page.lock!
          Pages::SnapshotWriter.new(page:).call
        end
        success(snapshot, status: :ok)
      rescue Error => e
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        failure(e.message)
      end

      private

      attr_reader :page
    end
  end
end

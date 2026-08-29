module Postnhost
  module Publishing
    class Pages::Unpublish < BaseService
      def initialize(page:)
        @page = page
      end

      def call
        snapshot = page.page_snapshot
        return failure("Page snapshot was not found", status: :not_found) unless snapshot

        Revision.hold do
          page.lock!
          snapshot.destroy!
        end
        success(true, status: :ok)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.message)
      end

      private

      attr_reader :page
    end
  end
end

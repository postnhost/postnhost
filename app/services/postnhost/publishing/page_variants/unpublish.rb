module Postnhost
  module Publishing
    class PageVariants::Unpublish < BaseService
      def initialize(page_variant:)
        @page_variant = page_variant
      end

      def call
        snapshot = page_variant.page_variant_snapshot
        return failure("Page variant snapshot was not found", status: :not_found) unless snapshot

        Revision.hold do
          page_variant.page.lock!
          page_variant.lock!
          snapshot.destroy!
        end
        success(true, status: :ok)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.message)
      end

      private

      attr_reader :page_variant
    end
  end
end

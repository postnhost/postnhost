module Postnhost
  module Publishing
    class PageVariants::Publish < BaseService
      def initialize(page_variant:)
        @page_variant = page_variant
      end

      def call
        snapshot = Revision.hold do
          page_variant.page.lock!
          page_variant.lock!
          PageVariants::SnapshotWriter.new(variant: page_variant).call
        end
        success(snapshot, status: :ok)
      rescue Error => e
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        failure(e.message)
      end

      private

      attr_reader :page_variant
    end
  end
end

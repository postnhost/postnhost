module Postnhost
  module Publishing
    class PageVariants::UnpublishMany < BaseService
      def initialize(page:, ids:)
        @page = page
        @ids = ids
      end

      def call
        BulkTransition.call(
          scope: page.page_variants,
          ids:,
          service_class: PageVariants::Unpublish,
          argument_name: :page_variant
        )
      end

      private

      attr_reader :page, :ids
    end
  end
end

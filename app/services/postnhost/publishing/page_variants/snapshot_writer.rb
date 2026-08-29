module Postnhost
  module Publishing
    class PageVariants::SnapshotWriter
      ATTRIBUTES = %i[language_id title title_tag og_title meta_description content].freeze

      def initialize(variant:)
        @variant = variant
      end

      def call
        validate!
        version = variant.paper_trail.save_with_version
        raise Error, "could not capture the snapshot source version" unless version&.persisted?

        snapshot = variant.page_variant_snapshot || variant.build_page_variant_snapshot
        snapshot.assign_attributes(
          variant.attributes.symbolize_keys.slice(*ATTRIBUTES).merge(
            page_id: variant.page_id,
            paper_trail_version: version
          )
        )
        snapshot.published_at ||= Time.current
        snapshot.save!
        snapshot
      end

      private

      attr_reader :variant

      def validate!
        errors = []
        errors << "base page must be published" unless variant.page.page_snapshot
        errors << "title can't be blank" if variant.title.blank?
        errors << "content can't be blank" if variant.content.blank?
        errors << "translation is still being generated" if variant.generating?
        raise Error, errors if errors.any?
      end
    end
  end
end

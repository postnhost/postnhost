module Postnhost
  module Publishing
    class Pages::SnapshotWriter
      ATTRIBUTES = %i[language_id title title_tag og_title meta_description content slug].freeze

      def initialize(page:)
        @page = page
      end

      def call
        validate!
        version = page.paper_trail.save_with_version
        raise Error, "could not capture the snapshot source version" unless version&.persisted?

        snapshot = page.page_snapshot || page.build_page_snapshot
        snapshot.assign_attributes(page.attributes.symbolize_keys.slice(*ATTRIBUTES).merge(paper_trail_version: version))
        snapshot.published_at ||= Time.current
        snapshot.save!
        snapshot
      end

      private

      attr_reader :page

      def validate!
        errors = []
        errors << "title can't be blank" if page.title.blank?
        errors << "content can't be blank" if page.content.blank?
        errors << "slug can't be blank" if page.slug.blank?
        errors << "language must exist" if page.language.blank?
        raise Error, errors if errors.any?

        RouteValidator.validate!(slug: page.slug, page_id: page.id)
      end
    end
  end
end

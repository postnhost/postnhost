module Postnhost
  module Publishing
    class ArticleVariants::SnapshotWriter
      ATTRIBUTES = %i[
        language_id title title_tag og_title schema_headline meta_description custom_excerpt auto_excerpt
        use_excerpt_as_meta_description content
      ].freeze

      def initialize(variant:)
        @variant = variant
      end

      def call
        validate!
        version = variant.paper_trail.save_with_version
        raise Error, "could not capture the snapshot source version" unless version&.persisted?

        snapshot = variant.article_variant_snapshot || variant.build_article_variant_snapshot
        snapshot.assign_attributes(
          variant.attributes.symbolize_keys.slice(*ATTRIBUTES).merge(
            article_id: variant.article_id,
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
        errors << "base article must be published" unless variant.article.article_snapshot
        errors << "title can't be blank" if variant.title.blank?
        errors << "content can't be blank" if variant.content.blank?
        errors << "translation is still being generated" if variant.generating?
        raise Error, errors if errors.any?
      end
    end
  end
end

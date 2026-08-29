module Postnhost
  module Publishing
    class Articles::SnapshotWriter
      ATTRIBUTES = %i[
        language_id title title_tag og_title schema_headline schema_article_type meta_description custom_excerpt
        auto_excerpt use_excerpt_as_meta_description content slug cover_image_alt top_pick
      ].freeze

      def initialize(article:)
        @article = article
      end

      def call
        validate!
        version = article.paper_trail.save_with_version
        raise Error, "could not capture the snapshot source version" unless version&.persisted?

        snapshot = article.article_snapshot || article.build_article_snapshot
        snapshot.assign_attributes(snapshot_attributes.merge(paper_trail_version: version))
        snapshot.published_at ||= Time.current
        snapshot.save!
        replace_categories!(snapshot)
        replace_authors!(snapshot)
        replace_suggestions!(snapshot)
        clear_schedule!
        snapshot
      end

      private

      attr_reader :article

      def validate!
        errors = []
        errors << "title can't be blank" if article.title.blank?
        errors << "content can't be blank" if article.content.blank?
        errors << "slug can't be blank" if article.slug.blank?
        errors << "language must exist" if article.language.blank?
        raise Error, errors if errors.any?

        RouteValidator.validate!(slug: article.slug, article_id: article.id)
      end

      def snapshot_attributes
        article.attributes.symbolize_keys.slice(*ATTRIBUTES).merge(
          cover_image_identifier: article.cover_image.identifier.presence
        )
      end

      def replace_categories!(snapshot)
        category_ids = article.article_categories.order(:id).pluck(:category_id)
        replace_joins!(snapshot.article_snapshot_categories, category_ids.map { |id| { category_id: id } })
      end

      def replace_authors!(snapshot)
        user_ids = article.article_authors.order(:position, :id).pluck(:user_id)
        rows = user_ids.each_with_index.map { |id, position| { user_id: id, position: } }
        replace_joins!(snapshot.article_snapshot_authors, rows)
      end

      def replace_suggestions!(snapshot)
        suggested_ids = article.article_suggestions.order(:position, :id).pluck(:suggested_article_id)
        rows = suggested_ids.each_with_index.map { |id, position| { suggested_article_id: id, position: } }
        replace_joins!(snapshot.article_snapshot_suggestions, rows)
      end

      # Deleting before inserting keeps the (snapshot, position) unique indexes satisfied without
      # per-row validation round trips; the indexes and check constraints enforce the same invariants.
      def replace_joins!(association, rows)
        association.delete_all
        association.insert_all(rows) if rows.any?
        association.reset
      end

      def clear_schedule!
        SolidQueue::Job.find_by(active_job_id: article.scheduled_job_id)&.destroy! if article.scheduled_job_id.present? && defined?(SolidQueue::Job)

        return if article.scheduled_at.blank? && article.scheduled_job_id.blank? && article.publication_error.blank?

        article.update!(scheduled_at: nil, scheduled_job_id: nil, publication_error: nil)
      end
    end
  end
end

module Postnhost
  module Publishing
    class Articles::PublishScheduled < BaseService
      def initialize(article_id:, job_id:)
        @article_id = article_id
        @job_id = job_id
      end

      def call
        article = Article.find_by(id: article_id)
        return failure("Article was not found", status: :not_found) unless article
        return failure("Article is not due for this job") unless due_for_this_job?(article)

        snapshot = Revision.hold do
          article.lock!
          Articles::SnapshotWriter.new(article:).call
        end
        success(snapshot, status: :ok)
      rescue Error => e
        record_publication_error(article, e.message)
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        record_publication_error(article, e.message)
        failure(e.message)
      end

      private

      attr_reader :article_id, :job_id

      def due_for_this_job?(article)
        article.scheduled_at.present? &&
          article.scheduled_at <= Time.current &&
          article.scheduled_job_id == job_id
      end

      def record_publication_error(article, message)
        article.update_columns(publication_error: message, updated_at: Time.current)
      end
    end
  end
end

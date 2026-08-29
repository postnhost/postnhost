module Postnhost
  module Publishing
    class Articles::Unpublish < BaseService
      def initialize(article:)
        @article = article
      end

      def call
        snapshot = article.article_snapshot
        return failure("Article snapshot was not found", status: :not_found) unless snapshot

        Revision.hold do
          article.lock!
          snapshot.destroy!
        end
        success(true, status: :ok)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.message)
      end

      private

      attr_reader :article
    end
  end
end

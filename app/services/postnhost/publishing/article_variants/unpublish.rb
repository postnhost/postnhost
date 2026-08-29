module Postnhost
  module Publishing
    class ArticleVariants::Unpublish < BaseService
      def initialize(article_variant:)
        @article_variant = article_variant
      end

      def call
        snapshot = article_variant.article_variant_snapshot
        return failure("Article variant snapshot was not found", status: :not_found) unless snapshot

        Revision.hold do
          article_variant.article.lock!
          article_variant.lock!
          snapshot.destroy!
        end
        success(true, status: :ok)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.message)
      end

      private

      attr_reader :article_variant
    end
  end
end

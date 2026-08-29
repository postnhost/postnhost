module Postnhost
  module Publishing
    class ArticleVariants::Publish < BaseService
      def initialize(article_variant:)
        @article_variant = article_variant
      end

      def call
        snapshot = Revision.hold do
          article_variant.article.lock!
          article_variant.lock!
          ArticleVariants::SnapshotWriter.new(variant: article_variant).call
        end
        success(snapshot, status: :ok)
      rescue Error => e
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        failure(e.message)
      end

      private

      attr_reader :article_variant
    end
  end
end

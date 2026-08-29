module Postnhost
  module Publishing
    class ArticleVariants::PublishMany < BaseService
      def initialize(article:, ids:)
        @article = article
        @ids = ids
      end

      def call
        BulkTransition.call(
          scope: article.article_variants,
          ids:,
          service_class: ArticleVariants::Publish,
          argument_name: :article_variant
        )
      end

      private

      attr_reader :article, :ids
    end
  end
end

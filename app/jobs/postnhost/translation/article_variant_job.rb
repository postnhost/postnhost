module Postnhost
  module Translation
    class ArticleVariantJob < ApplicationJob
      queue_as :default

      queue_with_priority 1

      retry_on StandardError, attempts: 3

      def perform(article_id, language_id)
        result = ArticleVariantTranslator.call(article_id:, language_id:)

        result.success? ? result : raise(StandardError, result.errors.to_sentence)
      end
    end
  end
end

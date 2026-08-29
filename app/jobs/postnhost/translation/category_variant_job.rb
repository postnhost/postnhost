module Postnhost
  module Translation
    class CategoryVariantJob < ApplicationJob
      queue_as :default

      queue_with_priority 1

      retry_on StandardError, attempts: 3

      def perform(category_id, language_id)
        result = CategoryVariantTranslator.call(category_id:, language_id:)

        result.success? ? result : raise(StandardError, result.errors.to_sentence)
      end
    end
  end
end

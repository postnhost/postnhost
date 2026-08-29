module Postnhost
  module Translation
    class PageVariantJob < ApplicationJob
      queue_as :default

      queue_with_priority 1

      retry_on StandardError, attempts: 3

      def perform(page_id, language_id)
        result = PageVariantTranslator.call(page_id:, language_id:)

        result.success? ? result : raise(StandardError, result.errors.to_sentence)
      end
    end
  end
end

module Postnhost
  module Translation
    class PageVariantTranslator < BaseService
      def initialize(page_id:, language_id:, llm_client: OpenaiLlmClient.new)
        @page_id = page_id
        @language_id = language_id
        @llm_client = llm_client
      end

      def call
        load_records
        return failure("Translation source or language not found") unless page && language
        return failure("Published translation source not found") unless source

        load_variant
        return failure("Translation variant not found") unless variant

        attributes = ContentTranslator.call(source:, language:, llm_client:)
        return finish_with_failure("Translation failed") if attributes[:title].blank? || attributes[:content].blank?

        variant.update!(attributes.merge(generating: false))
        success(variant)
      rescue StandardError => e
        mark_generation_finished
        failure(e.message)
      end

      private

      attr_reader :page_id, :language_id, :llm_client, :page, :language, :variant

      def load_records
        @page = Postnhost::Page.find_by(id: page_id)
        @language = Postnhost::Language.find_by(id: language_id)
      end

      def load_variant
        @variant = Postnhost::PageVariant.find_by(page:, language:)
      end

      def source
        @source ||= page.page_snapshot
      end

      def finish_with_failure(message)
        mark_generation_finished
        failure(message)
      end

      def mark_generation_finished
        variant&.update!(generating: false)
      end
    end
  end
end

module Postnhost
  module Translation
    class ArticleVariantTranslator < BaseService
      def initialize(article_id:, language_id:, llm_client: OpenaiLlmClient.new)
        @article_id = article_id
        @language_id = language_id
        @llm_client = llm_client
      end

      def call
        load_records
        return failure("Translation source or language not found") unless article && language
        return failure("Published translation source not found") unless source

        load_variant
        return failure("Translation variant not found") unless variant

        attributes = translated_attributes
        return finish_with_failure("Translation failed") if attributes[:title].blank? || attributes[:content].blank?

        variant.update!(attributes.merge(generating: false))
        success(variant)
      rescue StandardError => e
        mark_generation_finished
        failure(e.message)
      end

      private

      attr_reader :article_id, :language_id, :llm_client, :article, :language, :variant

      def load_records
        @article = Postnhost::Article.find_by(id: article_id)
        @language = Postnhost::Language.find_by(id: language_id)
      end

      def load_variant
        @variant = Postnhost::ArticleVariant.find_by(article:, language:)
      end

      def translated_attributes
        ContentTranslator.call(source:, language:, llm_client:).merge(
          schema_headline: translate_schema_headline,
          custom_excerpt: translate_custom_excerpt,
          use_excerpt_as_meta_description: source.use_excerpt_as_meta_description
        )
      end

      def source
        @source ||= article.article_snapshot
      end

      def translate_schema_headline
        return if source.schema_headline.blank?

        prompt = <<~PROMPT
          Translate this schema headline into #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it accurate and natural for #{language.name} speakers
          - Preserve meaning
          - Keep it suitable for structured data headline usage

          Schema headline to translate: #{source.schema_headline}

          Respond with only the translated schema headline, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_custom_excerpt
        return if source.custom_excerpt.blank?

        prompt = <<~PROMPT
          Translate this article excerpt into #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it concise and click-oriented
          - Preserve the original intent and tone
          - Make it natural for #{language.name} readers
          - Keep punctuation and sentence flow clean

          Excerpt to translate: #{source.custom_excerpt}

          Respond with only the translated excerpt, no additional text.
        PROMPT

        llm_client.text_response(prompt)
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

module Postnhost
  module Translation
    class CategoryVariantTranslator < BaseService
      def initialize(category_id:, language_id:, llm_client: OpenaiLlmClient.new)
        @category_id = category_id
        @language_id = language_id
        @llm_client = llm_client
      end

      def call
        load_records
        return failure("Category or language not found") unless category && language

        load_variant
        return failure("Category variant not found") unless variant

        attributes = translated_attributes
        return finish_with_failure("Translation failed") if attributes[:name].blank?

        variant.update!(attributes.merge(generating: false))
        success(variant)
      rescue StandardError => e
        mark_generation_finished
        failure(e.message)
      end

      private

      attr_reader :category_id, :language_id, :llm_client, :category, :language, :variant

      def load_records
        @category = Postnhost::Category.find_by(id: category_id)
        @language = Postnhost::Language.find_by(id: language_id)
      end

      def load_variant
        @variant = Postnhost::CategoryVariant.find_by(category:, language:)
      end

      def translated_attributes
        {
          name: translate_name,
          meta_description: translate_meta_description
        }
      end

      def translate_name
        prompt = <<~PROMPT
          You are a professional translator. Translate the following category name to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep the same tone and style
          - Make it natural for #{language.name} speakers
          - Preserve the meaning

          Category name to translate: #{category.name}

          Respond with only the translated name, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_meta_description
        return if category.meta_description.blank?

        prompt = <<~PROMPT
          You are a professional translator. Translate the following meta description to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it concise and SEO-friendly
          - Make it natural for #{language.name} speakers

          Meta description to translate: #{category.meta_description}

          Respond with only the translated meta description, no additional text.
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

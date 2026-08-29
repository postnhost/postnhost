module Postnhost
  module Translation
    class ContentTranslator < BaseService
      def initialize(source:, language:, llm_client:)
        @source = source
        @language = language
        @llm_client = llm_client
      end

      def call
        {
          title: translate_title,
          title_tag: translate_title_tag,
          og_title: translate_og_title,
          meta_description: translate_meta_description,
          content: translate_body
        }
      end

      private

      attr_reader :source, :language, :llm_client

      def translate_title
        prompt = <<~PROMPT
          You are a professional translator. Translate the following title to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep the same tone and style
          - Make it natural for #{language.name} speakers
          - Preserve the meaning and impact

          Title to translate: #{source.title}

          Respond with only the translated title, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_og_title
        return if source.og_title.blank?

        prompt = <<~PROMPT
          You are a professional translator. Translate the following Open Graph title to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it concise and compelling for social sharing
          - Preserve the original meaning and click intent
          - Make it natural for #{language.name} speakers

          OG title to translate: #{source.og_title}

          Respond with only the translated OG title, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_title_tag
        return if source.title_tag.blank?

        prompt = <<~PROMPT
          You are a professional translator. Translate the following title tag to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it SEO-optimized and concise
          - Make it natural for #{language.name} speakers
          - Preserve the meaning and marketing impact
          - Keep it suitable for HTML <title> tag

          Title tag to translate: #{source.title_tag}

          Respond with only the translated title tag, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_meta_description
        return if source.meta_description.blank?

        prompt = <<~PROMPT
          You are a professional translator. Translate the following meta description to #{language.name} (#{language.html_lang}).

          Requirements:
          - Keep it concise and SEO-friendly
          - Maintain the marketing tone
          - Make it natural for #{language.name} speakers

          Meta description to translate: #{source.meta_description}

          Respond with only the translated meta description, no additional text.
        PROMPT

        llm_client.text_response(prompt)
      end

      def translate_body
        prompt = <<~PROMPT
          You are a professional translator. Translate the following content to #{language.name} (#{language.html_lang}).

          Requirements:
          - Maintain the exact HTML structure and formatting
          - Keep the same tone of voice but adapt it to #{language.name} language specifics
          - Translate naturally while preserving meaning
          - Keep all HTML tags exactly as they are

          Content to translate:
          #{source.content}

          Respond with only the translated content, maintaining all HTML structure.
        PROMPT

        llm_client.text_response(prompt)
      end
    end
  end
end

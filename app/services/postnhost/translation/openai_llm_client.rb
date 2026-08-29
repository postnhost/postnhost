module Postnhost
  module Translation
    class OpenaiLlmClient
      DEFAULT_MODEL = "gpt-5.6-luna"
      TIMEOUT = 1240

      def initialize(client: nil)
        @client = client
      end

      def text_response(prompt, model: Postnhost.config.openai_gpt_model || DEFAULT_MODEL)
        response = client.responses.create(
          model: model,
          input: prompt
        )

        response.output_text.strip
      end

      private

      def client
        @client ||= OpenAI::Client.new(
          api_key: Postnhost.config.openai_api_key,
          timeout: TIMEOUT
        )
      end
    end
  end
end

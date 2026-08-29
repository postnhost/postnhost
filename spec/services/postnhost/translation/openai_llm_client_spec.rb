require "rails_helper"

RSpec.describe Postnhost::Translation::OpenaiLlmClient do
  describe "#text_response" do
    it "creates an OpenAI response and returns its stripped text" do
      stub_request(:post, "https://api.openai.com/v1/responses")
        .with(
          headers: { "Authorization" => "Bearer test-api-key" },
          body: { model: "gpt-test", input: "Translate this" }
        )
        .to_return(
          headers: { "Content-Type" => "application/json" },
          body: {
            id: "resp_test",
            object: "response",
            created_at: 1_754_329_600,
            status: "completed",
            model: "gpt-test",
            output: [
              {
                id: "msg_test",
                type: "message",
                status: "completed",
                role: "assistant",
                content: [{ type: "output_text", text: " Translated text \n", annotations: [] }]
              }
            ]
          }.to_json
        )
      client = OpenAI::Client.new(api_key: "test-api-key")

      result = described_class.new(client:).text_response("Translate this", model: "gpt-test")

      expect(result).to eq("Translated text")
    end

    it "configures the official client with the configured API key and timeout" do
      responses = double
      response = double(output_text: "Translated text")
      allow(responses).to receive(:create).and_return(response)
      client = double(responses:)
      allow(Postnhost.config).to receive(:openai_api_key).and_return("test-api-key")

      allow(OpenAI::Client).to receive(:new).and_return(client)

      described_class.new.text_response("Translate this")

      expect(OpenAI::Client).to have_received(:new).with(api_key: "test-api-key", timeout: described_class::TIMEOUT)
      expect(responses).to have_received(:create).with(model: described_class::DEFAULT_MODEL, input: "Translate this")
    end
  end
end

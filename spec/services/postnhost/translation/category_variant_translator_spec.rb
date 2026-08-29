require "rails_helper"

RSpec.describe Postnhost::Translation::CategoryVariantTranslator do
  let(:target_language) { create(:language, :spanish) }
  let(:llm_client) { instance_double(Postnhost::Translation::OpenaiLlmClient) }

  describe ".call" do
    it "translates category content into the target variant" do
      category = create(:category, name: "Original name", meta_description: "Original meta")
      variant = create(:category_variant, category:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return("Translated name", "Translated meta")

      result = described_class.call(category_id: category.id, language_id: target_language.id, llm_client:)

      expect(result).to be_success
      expect(result.value).to eq(variant)
      expect(variant.reload).to have_attributes(
        name: "Translated name",
        meta_description: "Translated meta",
        generating: false
      )
    end

    it "marks the variant as not generating when the translated name is blank" do
      category = create(:category)
      variant = create(:category_variant, category:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return(nil, "Translated meta")

      result = described_class.call(category_id: category.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Translation failed"])
      expect(variant.reload.generating).to be(false)
    end

    it "returns a failure when the source category is missing" do
      result = described_class.call(category_id: 999_999, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Category or language not found"])
    end

    it "clears the generating state when the translation client raises" do
      category = create(:category)
      variant = create(:category_variant, category:, language: target_language, generating: true)
      allow(llm_client).to receive(:text_response).and_raise(StandardError, "translation unavailable")

      result = described_class.call(category_id: category.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["translation unavailable"])
      expect(variant.reload.generating).to be(false)
    end
  end
end

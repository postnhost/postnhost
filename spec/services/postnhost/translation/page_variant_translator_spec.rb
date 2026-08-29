require "rails_helper"

RSpec.describe Postnhost::Translation::PageVariantTranslator do
  let(:user) { create(:user) }
  let(:source_language) { create(:language, :default) }
  let(:target_language) { create(:language, :spanish) }
  let(:llm_client) { instance_double(Postnhost::Translation::OpenaiLlmClient) }

  describe ".call" do
    it "translates page content into the target variant" do
      page = create(
        :page,
        :published,
        user:,
        language: source_language,
        title: "Original title",
        title_tag: "Original title tag",
        og_title: "Original OG title",
        meta_description: "Original meta",
        content: "<p>Original body</p>"
      )
      variant = create(:page_variant, page:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return(
        "Translated title",
        "Translated title tag",
        "Translated OG title",
        "Translated meta",
        "<p>Translated body</p>"
      )

      result = described_class.call(page_id: page.id, language_id: target_language.id, llm_client:)

      expect(result).to be_success
      expect(result.value).to eq(variant)
      expect(variant.reload).to have_attributes(
        title: "Translated title",
        title_tag: "Translated title tag",
        og_title: "Translated OG title",
        meta_description: "Translated meta",
        content: "<p>Translated body</p>",
        generating: false
      )
    end

    it "marks the variant as not generating when required translated content is blank" do
      page = create(:page, :published, user:, language: source_language)
      variant = create(:page_variant, page:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return("Translated title", "Translated title tag", "Translated meta", nil)

      result = described_class.call(page_id: page.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Translation failed"])
      expect(variant.reload.generating).to be(false)
    end

    it "returns a failure when the source page is missing" do
      result = described_class.call(page_id: 999_999, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Translation source or language not found"])
    end

    it "clears the generating state when the translation client raises" do
      page = create(:page, :published, user:, language: source_language)
      variant = create(:page_variant, page:, language: target_language, generating: true)
      allow(llm_client).to receive(:text_response).and_raise(StandardError, "translation unavailable")

      result = described_class.call(page_id: page.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["translation unavailable"])
      expect(variant.reload.generating).to be(false)
    end
  end
end

require "rails_helper"

RSpec.describe Postnhost::Translation::ArticleVariantTranslator do
  let(:user) { create(:user) }
  let(:source_language) { create(:language, :default) }
  let(:target_language) { create(:language, :spanish) }
  let(:llm_client) { instance_double(Postnhost::Translation::OpenaiLlmClient) }

  describe ".call" do
    it "translates article content into the target variant" do
      article = create(
        :article,
        :published,
        user:,
        language: source_language,
        title: "Original title",
        title_tag: "Original title tag",
        og_title: "Original OG title",
        schema_headline: "Original schema headline",
        meta_description: "Original meta",
        custom_excerpt: "Original excerpt",
        use_excerpt_as_meta_description: true,
        content: "<p>Original body</p>"
      )
      variant = create(:article_variant, article:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return(
        "Translated title",
        "Translated title tag",
        "Translated OG title",
        "Translated meta",
        "<p>Translated body</p>",
        "Translated schema headline",
        "Translated excerpt"
      )

      result = described_class.call(article_id: article.id, language_id: target_language.id, llm_client:)

      expect(result).to be_success
      expect(result.value).to eq(variant)
      expect(variant.reload).to have_attributes(
        title: "Translated title",
        title_tag: "Translated title tag",
        og_title: "Translated OG title",
        schema_headline: "Translated schema headline",
        meta_description: "Translated meta",
        custom_excerpt: "Translated excerpt",
        use_excerpt_as_meta_description: true,
        content: "<p>Translated body</p>",
        generating: false
      )
    end

    it "marks the variant as not generating when required translated content is blank" do
      article = create(:article, :published, user:, language: source_language)
      variant = create(:article_variant, article:, language: target_language, generating: true)

      allow(llm_client).to receive(:text_response).and_return(nil, "Translated title tag", "Translated meta", "<p>Translated body</p>")

      result = described_class.call(article_id: article.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Translation failed"])
      expect(variant.reload.generating).to be(false)
    end

    it "returns a failure when the source article is missing" do
      result = described_class.call(article_id: 999_999, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["Translation source or language not found"])
    end

    it "clears the generating state when the translation client raises" do
      article = create(:article, :published, user:, language: source_language)
      variant = create(:article_variant, article:, language: target_language, generating: true)
      allow(llm_client).to receive(:text_response).and_raise(StandardError, "translation unavailable")

      result = described_class.call(article_id: article.id, language_id: target_language.id, llm_client:)

      expect(result).not_to be_success
      expect(result.errors).to eq(["translation unavailable"])
      expect(variant.reload.generating).to be(false)
    end
  end
end

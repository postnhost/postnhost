require "rails_helper"

RSpec.describe Postnhost::Translation::ArticleVariantJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:article) { create(:article, user:) }
  let(:language) { create(:language, :spanish) }
  let(:article_variant) { create(:article_variant, article:, language:) }

  describe "#perform" do
    context "when translation succeeds" do
      before do
        allow(Postnhost::Translation::ArticleVariantTranslator).to receive(:call)
          .with(article_id: article.id, language_id: language.id)
          .and_return(Postnhost::ServiceResult.new(value: article_variant, errors: []))
      end

      it "completes successfully without raising an error" do
        expect { described_class.perform_now(article.id, language.id) }.not_to raise_error
      end

      it "calls the translator with correct parameters" do
        described_class.perform_now(article.id, language.id)

        expect(Postnhost::Translation::ArticleVariantTranslator).to have_received(:call)
          .with(article_id: article.id, language_id: language.id)
      end
    end

    context "when article does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(999_999, language.id) }.not_to raise_error
      end
    end

    context "when language does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(article.id, 999_999) }.not_to raise_error
      end
    end
  end

  describe "job configuration" do
    it "uses the default queue" do
      expect(described_class.queue_name).to eq("default")
    end

    it "has priority 1" do
      expect(described_class.priority).to eq(1)
    end
  end
end

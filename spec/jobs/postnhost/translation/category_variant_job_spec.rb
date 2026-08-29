require "rails_helper"

RSpec.describe Postnhost::Translation::CategoryVariantJob, type: :job do
  include ActiveJob::TestHelper

  let(:category) { create(:category) }
  let(:language) { create(:language, :spanish) }
  let(:category_variant) { create(:category_variant, category:, language:) }

  describe "#perform" do
    context "when translation succeeds" do
      before do
        allow(Postnhost::Translation::CategoryVariantTranslator).to receive(:call)
          .with(category_id: category.id, language_id: language.id)
          .and_return(Postnhost::ServiceResult.new(value: category_variant, errors: []))
      end

      it "completes successfully without raising an error" do
        expect { described_class.perform_now(category.id, language.id) }.not_to raise_error
      end

      it "calls the translator with correct parameters" do
        described_class.perform_now(category.id, language.id)

        expect(Postnhost::Translation::CategoryVariantTranslator).to have_received(:call)
          .with(category_id: category.id, language_id: language.id)
      end
    end

    context "when category does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(999_999, language.id) }.not_to raise_error
      end
    end

    context "when language does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(category.id, 999_999) }.not_to raise_error
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

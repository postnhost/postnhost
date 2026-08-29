require "rails_helper"

RSpec.describe Postnhost::Translation::PageVariantJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:page) { create(:page, user:) }
  let(:language) { create(:language, :spanish) }
  let(:page_variant) { create(:page_variant, page:, language:) }

  describe "#perform" do
    context "when translation succeeds" do
      before do
        allow(Postnhost::Translation::PageVariantTranslator).to receive(:call)
          .with(page_id: page.id, language_id: language.id)
          .and_return(Postnhost::ServiceResult.new(value: page_variant, errors: []))
      end

      it "completes successfully without raising an error" do
        expect { described_class.perform_now(page.id, language.id) }.not_to raise_error
      end

      it "calls the translator with correct parameters" do
        described_class.perform_now(page.id, language.id)

        expect(Postnhost::Translation::PageVariantTranslator).to have_received(:call)
          .with(page_id: page.id, language_id: language.id)
      end
    end

    context "when page does not exist" do
      it "does not raise an error" do
        expect { described_class.perform_now(999_999, language.id) }.not_to raise_error
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

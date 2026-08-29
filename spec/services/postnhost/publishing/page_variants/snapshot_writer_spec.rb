require "rails_helper"

RSpec.describe Postnhost::Publishing::PageVariants::SnapshotWriter, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "writes a page variant snapshot" do
    page = create(:page, :published, language: default_language)
    variant = create(:page_variant, page:, language: spanish)

    snapshot = described_class.new(variant:).call

    expect(snapshot).to be_a(Postnhost::Snapshot::PageVariant)
    expect(snapshot.title).to eq(variant.title)
    expect(snapshot.page_snapshot).to eq(page.page_snapshot)
  end

  it "reports invalid and unfinished translations" do
    page = create(:page, language: default_language)
    variant = create(:page_variant, page:, language: spanish)
    variant.update_columns(title: nil, content: nil, generating: true)

    expect do
      described_class.new(variant:).call
    end.to raise_error(Postnhost::Publishing::Error) { |error|
      expect(error.messages).to contain_exactly(
        "base page must be published",
        "title can't be blank",
        "content can't be blank",
        "translation is still being generated"
      )
    }
  end
end

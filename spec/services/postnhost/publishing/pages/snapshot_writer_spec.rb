require "rails_helper"

RSpec.describe Postnhost::Publishing::Pages::SnapshotWriter, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "writes the public page snapshot" do
    page = create(:page, language: default_language)

    snapshot = described_class.new(page:).call

    expect(snapshot).to be_a(Postnhost::Snapshot::Page)
    expect(snapshot.attributes.slice("title", "content", "slug")).to eq(page.attributes.slice("title", "content", "slug"))
  end

  it "reports every missing publication requirement" do
    page = create(:page, language: default_language)
    page.update_columns(title: nil, content: nil, slug: nil, language_id: nil)

    expect do
      described_class.new(page:).call
    end.to raise_error(Postnhost::Publishing::Error) { |error|
      expect(error.messages).to contain_exactly(
        "title can't be blank",
        "content can't be blank",
        "slug can't be blank",
        "language must exist"
      )
    }
  end
end

require "rails_helper"

RSpec.describe Postnhost::Snapshot::Page, type: :model do
  subject(:snapshot) { build(:page_snapshot) }

  it { is_expected.to belong_to(:page).class_name("Postnhost::Page") }
  it { is_expected.to belong_to(:language).class_name("Postnhost::Language") }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:published_at) }

  it "uses the page snapshot table" do
    expect(described_class.table_name).to eq("postnhost_page_snapshots")
  end

  it "prefers the title tag for metadata" do
    snapshot.title = "Page title"
    snapshot.title_tag = "SEO title"

    expect(snapshot.title_for_meta).to eq("SEO title")
  end
end

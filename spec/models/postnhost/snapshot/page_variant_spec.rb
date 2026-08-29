require "rails_helper"

RSpec.describe Postnhost::Snapshot::PageVariant, type: :model do
  subject(:snapshot) { described_class.new }

  it { is_expected.to belong_to(:page_variant).class_name("Postnhost::PageVariant") }
  it { is_expected.to belong_to(:page).class_name("Postnhost::Page") }
  it { is_expected.to belong_to(:language).class_name("Postnhost::Language") }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:published_at) }

  it "uses the page variant snapshot table" do
    expect(described_class.table_name).to eq("postnhost_page_variant_snapshots")
  end

  it "is always published" do
    expect(snapshot).to be_published
  end
end

require "rails_helper"

RSpec.describe Postnhost::Snapshot::ArticleVariant, type: :model do
  subject(:snapshot) { described_class.new }

  it { is_expected.to belong_to(:article_variant).class_name("Postnhost::ArticleVariant") }
  it { is_expected.to belong_to(:article).class_name("Postnhost::Article") }
  it { is_expected.to belong_to(:language).class_name("Postnhost::Language") }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:published_at) }

  it "uses the article variant snapshot table" do
    expect(described_class.table_name).to eq("postnhost_article_variant_snapshots")
  end

  it "is always published" do
    expect(snapshot).to be_published
  end
end

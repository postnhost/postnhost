require "rails_helper"

RSpec.describe Postnhost::Snapshot::ArticleSuggestion, type: :model do
  subject(:article_suggestion) do
    described_class.new(
      article_snapshot: create(:article_snapshot),
      suggested_article: create(:article),
      position: 0
    )
  end

  it { is_expected.to belong_to(:article_snapshot).class_name("Postnhost::Snapshot::Article") }
  it { is_expected.to belong_to(:suggested_article).class_name("Postnhost::Article") }
  it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }

  it "uses the article snapshot suggestion table" do
    expect(described_class.table_name).to eq("postnhost_article_snapshot_suggestions")
  end
end

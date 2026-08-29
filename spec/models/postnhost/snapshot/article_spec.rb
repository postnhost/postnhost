require "rails_helper"

RSpec.describe Postnhost::Snapshot::Article, type: :model do
  subject(:snapshot) { build(:article_snapshot) }

  it { is_expected.to belong_to(:article) }
  it { is_expected.to belong_to(:language) }
  it { is_expected.to belong_to(:paper_trail_version).class_name("Postnhost::Version") }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:slug) }
  it { is_expected.to validate_presence_of(:published_at) }

  it "uses the article snapshot table" do
    expect(described_class.table_name).to eq("postnhost_article_snapshots")
  end

  it "is always published" do
    expect(snapshot).to be_published
  end

  it "memoizes suggestions for the same language and limit" do
    language = create(:language, :default)
    article = create(:article, :published, language:)
    snapshot = described_class.find_by!(article_id: article.id)

    allow(snapshot).to receive(:manual_suggestions).and_call_original

    first_result = snapshot.suggestions_for(language:)
    second_result = snapshot.suggestions_for(language:)

    expect(snapshot).to have_received(:manual_suggestions).once
    expect(second_result).to equal(first_result)
  end
end

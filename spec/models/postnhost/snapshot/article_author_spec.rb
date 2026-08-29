require "rails_helper"

RSpec.describe Postnhost::Snapshot::ArticleAuthor, type: :model do
  subject(:article_author) do
    described_class.new(article_snapshot: create(:article_snapshot), user: create(:user), position: 0)
  end

  it { is_expected.to belong_to(:article_snapshot).class_name("Postnhost::Snapshot::Article") }
  it { is_expected.to belong_to(:user).class_name("Postnhost::User") }
  it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }

  it "uses the article snapshot author table" do
    expect(described_class.table_name).to eq("postnhost_article_snapshot_authors")
  end
end

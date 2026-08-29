require "rails_helper"

RSpec.describe Postnhost::Snapshot::ArticleCategory, type: :model do
  subject(:article_category) do
    described_class.new(article_snapshot: create(:article_snapshot), category: create(:category))
  end

  it { is_expected.to belong_to(:article_snapshot).class_name("Postnhost::Snapshot::Article") }
  it { is_expected.to belong_to(:category).class_name("Postnhost::Category") }

  it "uses the article snapshot category table" do
    expect(described_class.table_name).to eq("postnhost_article_snapshot_categories")
  end
end

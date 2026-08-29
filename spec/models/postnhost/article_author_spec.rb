require "rails_helper"

RSpec.describe Postnhost::ArticleAuthor, type: :model do
  subject(:article_author) { build(:article_author) }

  describe "associations" do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:article_id) }
  end

  describe "callbacks" do
    it "assigns position automatically" do
      article = create(:article)
      first = create(:article_author, article:, position: 1)
      second = create(:article_author, article:, position: nil)

      expect(first.position).to eq(1)
      expect(second.position).to eq(2)
    end
  end
end

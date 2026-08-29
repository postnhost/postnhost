require "rails_helper"

RSpec.describe Postnhost::ArticleCategory, type: :model do
  describe "validations" do
    subject { build(:article_category) }

    it "validates uniqueness of article_id scoped to category_id" do
      existing_category = create(:article_category)
      new_category = build(:article_category, article: existing_category.article, category: existing_category.category)

      expect(new_category).not_to be_valid
      expect(new_category.errors[:article_id]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:article).touch(true) }
    it { is_expected.to belong_to(:category).counter_cache(:articles_count).touch(true) }
  end
end

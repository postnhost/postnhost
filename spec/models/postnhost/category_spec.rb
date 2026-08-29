require "rails_helper"

RSpec.describe Postnhost::Category, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "associations" do
    it { is_expected.to have_many(:article_categories).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_categories) }
    it { is_expected.to have_many(:category_variants).dependent(:destroy) }
  end

  describe ".with_category_variants_for_language" do
    let(:default_language) { create(:language, :default) }
    let(:other_language) { create(:language, :german) }

    it "does not eager-load variants for the default language" do
      rel = described_class.with_category_variants_for_language(default_language)
      expect(rel.includes_values).to eq([])
    end

    it "eager-loads variants for a non-default language" do
      rel = described_class.with_category_variants_for_language(other_language)
      expect(rel.includes_values).to eq([:category_variants])
    end

    it "eager-loads variants when language is nil" do
      rel = described_class.with_category_variants_for_language(nil)
      expect(rel.includes_values).to eq([:category_variants])
    end
  end

  describe "callbacks" do
    let(:category) { create(:category) }
    let(:article) { create(:article) }

    before do
      create(:article_category, article:, category:)
    end

    it "touches associated articles after save when name changes" do
      original_time = article.updated_at
      travel(1.second) do
        category.update!(name: "New Name")
        expect(article.reload.updated_at).to be > original_time
      end
    end

    it "touches associated articles after save when slug changes" do
      original_time = article.updated_at
      travel(1.second) do
        category.update!(slug: "new-slug")
        expect(article.reload.updated_at).to be > original_time
      end
    end

    it "touches associated articles after destroy" do
      original_time = article.updated_at
      travel(1.second) do
        category.destroy!
        expect(article.reload.updated_at).to be > original_time
      end
    end
  end
end

require "rails_helper"

RSpec.describe Postnhost::ArticleSuggestion, type: :model do
  describe "validations" do
    it "validates uniqueness of suggested_article_id scoped to article_id" do
      existing_suggestion = create(:article_suggestion)
      new_suggestion = build(
        :article_suggestion,
        article: existing_suggestion.article,
        suggested_article: existing_suggestion.suggested_article
      )

      expect(new_suggestion).not_to be_valid
      expect(new_suggestion.errors[:suggested_article_id]).to include("has already been taken")
    end

    describe "cannot_suggest_self" do
      let(:article) { create(:article) }

      it "is valid when suggesting a different article" do
        suggestion = build(:article_suggestion, article:)
        expect(suggestion).to be_valid
      end

      it "is invalid when suggesting the same article" do
        suggestion = build(:article_suggestion, article:, suggested_article: article)
        expect(suggestion).not_to be_valid
        expect(suggestion.errors[:suggested_article]).to include("can't be the same as the article")
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:article).touch(true) }
    it { is_expected.to belong_to(:suggested_article).class_name("Postnhost::Article") }
  end

  describe "default scope" do
    let!(:higher_position_suggestion) { create(:article_suggestion, position: 2) }
    let!(:lower_position_suggestion) { create(:article_suggestion, position: 1) }

    it "orders by position" do
      expect(described_class.all).to eq([lower_position_suggestion, higher_position_suggestion])
    end
  end
end

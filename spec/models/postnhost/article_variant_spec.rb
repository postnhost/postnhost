require "rails_helper"

RSpec.describe Postnhost::ArticleVariant, type: :model do
  describe "validations" do
    subject { build(:article_variant) }

    it "validates uniqueness of article_id scoped to language_id" do
      existing_variant = create(:article_variant)
      new_variant = build(:article_variant, article: existing_variant.article, language: existing_variant.language)

      expect(new_variant).not_to be_valid
      expect(new_variant.errors[:article_id]).to include("has already been taken")
    end

    it "rejects custom excerpt that exceeds character limit" do
      variant = build(:article_variant, custom_excerpt: "a" * 161)

      expect(variant).not_to be_valid
      expect(variant.errors[:custom_excerpt]).to include("must be 160 characters or fewer")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:article).counter_cache(true).touch(true) }
    it { is_expected.to belong_to(:language).counter_cache(true) }
    it { is_expected.to have_one(:user).through(:article) }
  end

  describe "versioning" do
    it "is versioned with the correct attributes" do
      expect(described_class.paper_trail_options[:only]).to eq(
        %w[title title_tag og_title schema_headline meta_description custom_excerpt use_excerpt_as_meta_description content]
      )
      expect(described_class.paper_trail_options[:on]).to eq([])
    end
  end

  describe "callbacks" do
    it "computes auto excerpt from content on save" do
      variant = create(
        :article_variant,
        custom_excerpt: nil,
        content: "<p>Localized first sentence.</p><p>Localized second sentence.</p><p>Localized extra sentence.</p>"
      )

      expect(variant.auto_excerpt).to eq("Localized first sentence. Localized second sentence.")
    end
  end
end

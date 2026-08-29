require "rails_helper"

RSpec.describe Postnhost::PageVariant, type: :model do
  describe "validations" do
    subject { build(:page_variant) }

    it "validates uniqueness of page_id scoped to language_id" do
      existing_variant = create(:page_variant)
      new_variant = build(:page_variant, page: existing_variant.page, language: existing_variant.language)

      expect(new_variant).not_to be_valid
      expect(new_variant.errors[:page_id]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:page).counter_cache(true).touch(true) }
    it { is_expected.to belong_to(:language) }
    it { is_expected.to have_one(:user).through(:page) }
  end

  describe "versioning" do
    it "is versioned with the correct attributes" do
      expect(described_class.paper_trail_options[:only]).to eq(
        %w[title title_tag og_title meta_description content]
      )
      expect(described_class.paper_trail_options[:on]).to eq([])
    end

    it "compares draft changes to the snapshot" do
      variant = create(:page_variant, :published, title: "Original")

      variant.update!(title: "Draft edit")

      expect(variant.page_variant_snapshot.title).to eq("Original")
      expect(variant.unpublished_changes?).to be(true)
    end
  end
end

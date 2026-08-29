require "rails_helper"

RSpec.describe Postnhost::CategoryVariant, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "allows a blank name while AI translation is in progress" do
      variant = build(:category_variant, name: nil, generating: true)

      expect(variant).to be_valid
    end

    it "rejects the site default language" do
      default_language = create(:language, :default)
      variant = build(:category_variant, language: default_language)

      expect(variant).not_to be_valid
      expect(variant.errors[:language_id]).to include("cannot be the site default language; edit the category for that locale")
    end

    it "validates uniqueness of category_id scoped to language_id" do
      existing_variant = create(:category_variant)
      new_variant = build(:category_variant, category: existing_variant.category, language: existing_variant.language)

      expect(new_variant).not_to be_valid
      expect(new_variant.errors[:category_id]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:category).touch(true) }
    it { is_expected.to belong_to(:language) }
  end

  it "bumps the public site revision once through its category" do
    variant = build(:category_variant, category: create(:category), language: create(:language, :german))
    revision = Postnhost::PublicSiteRevision.current.revision

    variant.save!

    expect(Postnhost::PublicSiteRevision.current.revision).to eq(revision + 1)
  end
end

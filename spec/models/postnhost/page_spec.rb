require "rails_helper"

RSpec.describe Postnhost::Page, type: :model do
  subject(:page) { build(:page) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:language).optional }
    it { is_expected.to have_many(:page_variants).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to allow_value(nil).for(:slug) }
    it { is_expected.to allow_value("my-valid-slug-1").for(:slug) }
    it { is_expected.not_to allow_value("Invalid Slug").for(:slug) }

    it "rejects slug used by an article" do
      create(:article, slug: "shared-slug")
      record = build(:page, slug: "shared-slug")

      expect(record).not_to be_valid
      expect(record.errors[:slug]).to include("has already been taken")
    end

    it "rejects a primary language that duplicates an existing translation" do
      spanish = create(:language, :spanish)
      page = create(:page, language: create(:language, :default))
      create(:page_variant, page:, language: spanish)

      page.language = spanish

      expect(page).not_to be_valid
      expect(page.errors[:language_id]).to include("cannot duplicate an existing translation")
    end
  end

  describe "callbacks" do
    it "generates slug from title when slug is blank" do
      record = build(:page, title: "My New Page!", slug: nil)

      record.validate

      expect(record.slug).to eq("my-new-page")
    end

    it "increments generated slugs across page and article collisions" do
      create(:page, slug: "shared-title")
      create(:article, slug: "shared-title-1")
      record = build(:page, title: "Shared Title", slug: nil)

      record.validate

      expect(record.slug).to eq("shared-title-2")
    end

    it "normalizes blank slug to nil" do
      record = build(:page, title: nil, slug: " ")

      record.validate

      expect(record.slug).to be_nil
    end
  end

  describe ".published" do
    it "returns only pages with snapshots" do
      public_page = create(:page, :published)
      private_page = create(:page)

      expect(described_class.published).to include(public_page)
      expect(described_class.published).not_to include(private_page)
    end
  end

  describe "#title_for_meta" do
    it "returns title_tag when present" do
      record = build(:page, title: "Main Title", title_tag: "Meta Title")

      expect(record.title_for_meta).to eq("Meta Title")
    end

    it "falls back to title when title_tag is blank" do
      record = build(:page, title: "Main Title", title_tag: "")

      expect(record.title_for_meta).to eq("Main Title")
    end
  end
end

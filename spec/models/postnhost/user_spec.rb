require "rails_helper"

RSpec.describe Postnhost::User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:articles).dependent(:nullify) }
    it { is_expected.to have_many(:article_authors).dependent(:destroy) }
    it { is_expected.to have_many(:authored_articles).through(:article_authors) }
    it { is_expected.to have_many(:pages).dependent(:restrict_with_error) }
  end

  describe "deletion" do
    it "preserves the user and their pages" do
      record = create(:user)
      owned_page = create(:page, user: record)

      expect(record.destroy).to be(false)
      expect(record.errors[:base]).to be_present
      expect(record).to be_persisted
      expect(owned_page.reload).to be_persisted
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid").for(:email) }
    it { is_expected.to allow_value("author-slug-1").for(:slug) }
    it { is_expected.to validate_length_of(:password).is_at_least(6) }

    it "enforces unique slugs after normalization" do
      create(:user, slug: "author")
      record = build(:user, slug: "AUTHOR")

      expect(record).not_to be_valid
      expect(record.errors[:slug]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    it "normalizes email before validation" do
      record = build(:user, email: "  TEST@Example.COM  ")

      record.validate

      expect(record.email).to eq("test@example.com")
    end

    it "generates slug from name when missing" do
      record = build(:user, slug: nil, name: "Jane Doe")

      record.validate

      expect(record.slug).to eq("jane-doe")
    end

    it "increments generated slugs when an author name already exists" do
      create(:user, slug: "jane-doe")
      record = build(:user, slug: nil, name: "Jane Doe")

      record.validate

      expect(record.slug).to eq("jane-doe-1")
    end

    it "normalizes slug input format before validation" do
      record = build(:user, slug: " Invalid Slug ")

      record.validate

      expect(record.slug).to eq("invalid-slug")
    end
  end

  describe "#authenticate" do
    it "authenticates with the valid password" do
      record = create(:user, password: "secret12", password_confirmation: "secret12")

      expect(record.authenticate("secret12")).to eq(record)
      expect(record.authenticate("wrong")).to be(false)
    end
  end
end

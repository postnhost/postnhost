require "rails_helper"

RSpec.describe "Categories", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before { sign_in_as(user) }

  describe "listing" do
    it "displays all categories" do
      categories = create_list(:category, 3)
      visit postnhost.categories_path

      expect(page).to have_text("Categories")
      categories.each { |category| expect(page).to have_text(category.name) }
    end
  end

  describe "creating" do
    it "creates with valid attributes" do
      visit postnhost.new_category_path

      fill_in "Name", with: "Technology"
      fill_in "Slug", with: "technology"
      fill_in "Description", with: "Tech articles"

      click_button "Create Category"

      expect(page).to have_text("Technology")
      expect(Postnhost::Category.exists?(slug: "technology")).to be(true)
    end

    it "shows validation errors" do
      visit postnhost.new_category_path
      click_button "Create Category"
      expect(page).to have_text("can't be blank")
    end
  end

  describe "viewing" do
    it "displays details" do
      category = create(:category, name: "Technology", slug: "tech")
      visit postnhost.category_path(category)

      expect(page).to have_text("Technology")
      expect(page).to have_text("tech")
    end
  end

  describe "updating" do
    it "updates with valid attributes" do
      category = create(:category, name: "Old")
      visit postnhost.edit_category_path(category)

      fill_in "Name", with: "New"
      click_button "Update Category"

      expect(page).to have_text("New")
    end
  end
end

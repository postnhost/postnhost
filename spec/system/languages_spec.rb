require "rails_helper"

RSpec.describe "Languages", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before { sign_in_as(user) }

  describe "listing" do
    it "displays all languages" do
      languages = create_list(:language, 3, default: false)
      visit postnhost.languages_path

      expect(page).to have_text("Languages")
      languages.each { |language| expect(page).to have_text(language.name) }
    end
  end

  describe "creating" do
    it "creates with valid attributes" do
      visit postnhost.new_language_path

      fill_in "Name", with: "Spanish"
      fill_in "Language Code", with: "es"

      click_button "Create Language"

      expect(page).to have_text("Spanish")
      expect(Postnhost::Language.exists?(html_lang: "es")).to be(true)
    end

    it "shows validation errors" do
      visit postnhost.new_language_path
      click_button "Create Language"
      expect(page).to have_text("can't be blank")
    end
  end

  describe "viewing" do
    it "displays details" do
      language = create(:language, name: "Spanish", html_lang: "es")
      visit postnhost.language_path(language)

      expect(page).to have_text("Spanish")
      expect(page).to have_text("es")
    end
  end

  describe "updating" do
    it "updates with valid attributes" do
      language = create(:language, name: "Old")
      visit postnhost.edit_language_path(language)

      fill_in "Name", with: "New"
      click_button "Update Language"

      expect(page).to have_text("New")
    end
  end
end

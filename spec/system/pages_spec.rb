require "rails_helper"

RSpec.describe "Pages", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before { sign_in_as(user) }

  describe "index page" do
    it "shows dynamic pages and code-defined static pages" do
      create(:page, :published, user:, title: "Pricing", slug: "pricing")

      visit postnhost.pages_path

      expect(page).to have_text("Pages")
      expect(page).to have_text("Pricing")
      expect(page).to have_text("/pricing")
      expect(page).to have_text("Code-defined static pages")
      expect(page).to have_text("Terms")
      expect(page).to have_text("/terms")
    end

    it "creates a new draft page from the new page action" do
      visit postnhost.pages_path

      click_link "New Page", match: :first

      expect(page).to have_current_path(%r{/pages/\d+/edit}, url: true)
      expect(Postnhost::Page.count).to eq(1)

      created_page = Postnhost::Page.last
      expect(created_page.user).to eq(user)
      expect(created_page).not_to be_published
    end
  end

  describe "publish flow" do
    it "publishes and unpublishes a page through editor actions" do
      page_record = create(:page, user:, title: "Pricing", slug: "pricing")

      visit postnhost.edit_page_path(page_record)

      click_button "Actions" if page.has_no_link?("Publish Now", wait: 1)
      expect(page).to have_link("Publish Now")

      click_link "Publish Now"

      expect(page).to have_link("Unpublish")
      expect(page).to have_link("Open", href: postnhost.public_static_page_path(slug: "pricing"))
      expect(page_record.reload).to be_published

      click_button "Actions" if page.has_no_link?("Unpublish", wait: 1)
      click_link "Unpublish"

      expect(page).to have_link("Publish Now")
      expect(page_record.reload).not_to be_published
    end
  end
end

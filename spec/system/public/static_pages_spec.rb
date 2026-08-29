require "rails_helper"

RSpec.describe "Public Static Pages", type: :system do
  let!(:default_language) { create(:language, :default, name: "English", html_lang: "en") }
  let!(:spanish_language) { create(:language, name: "Spanish", html_lang: "es", default: false) }
  let!(:user) { create(:user) }

  describe "code-defined templates" do
    it "renders static template on root path" do
      visit postnhost.public_static_page_path(slug: "terms")

      expect(page).to have_text("Terms")
      expect(page).to have_text("Terms page from namespaced static path")
    end

    it "renders static template on localized path" do
      visit postnhost.localized_public_static_page_path(locale: "es", slug: "terms")

      expect(page).to have_text("Terms")
      expect(page).to have_text("Terms page from namespaced static path")
    end
  end

  describe "dynamic pages" do
    it "renders a published dynamic page" do
      create(
        :page,
        :published,
        user:,
        slug: "dynamic-terms",
        title: "Dynamic Terms",
        content: "<p>Dynamic terms body</p>"
      )

      visit postnhost.public_static_page_path(slug: "dynamic-terms")

      expect(page).to have_text("Dynamic Terms")
      expect(page).to have_text("Dynamic terms body")
    end
  end
end

require "rails_helper"

RSpec.describe "Public Categories", type: :system do
  let!(:default_language) { create(:language, :default, name: "English", html_lang: "en") }
  let!(:spanish) { create(:language, name: "Spanish", html_lang: "es", default: false) }
  let!(:user) { create(:user, name: "John Doe") }

  describe "index" do
    it "displays articles in a category" do
      category = create(:category, name: "Technology", slug: "technology")
      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "Tech Article")
      article.categories << category
      Postnhost::Publishing::Articles::Publish.call(article:)

      visit postnhost.public_category_path(category.slug)

      expect(page).to have_text("Tech Article")
    end

    it "displays category with translated name in another language" do
      category = create(:category, name: "Technology", slug: "technology")
      create(:category_variant, category:, language: spanish, name: "Tecnología")

      article = create(:article, :published,
                       user:,
                       language: default_language,
                       title: "Tech Article")
      article.categories << category
      Postnhost::Publishing::Articles::Publish.call(article:)

      create(:article_variant, :published,
             article:,
             language: spanish,
             title: "Tech Article ES",
             content: "<p>Spanish content</p>")

      visit postnhost.localized_public_category_path(locale: "es", category_slug: category.slug)

      expect(page).to have_text("Tech Article ES")
      expect(page).to have_text("Tecnología")
    end
  end
end

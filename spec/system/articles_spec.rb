require "rails_helper"

RSpec.describe "Articles", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before { sign_in_as(user) }

  describe "index page" do
    it "displays all articles" do
      articles = create_list(:article, 3, user:, language: default_language)

      visit postnhost.articles_path

      articles.each do |article|
        expect(page).to have_text(article.title)
        expect(page).to have_text("Draft")
      end
    end

    it "displays article details" do
      create(:article, :published,
             user:,
             language: default_language,
             title: "Test Article",
             custom_excerpt: "Custom excerpt shown on admin index.",
             meta_description: "This is a test description",
             updated_at: 2.days.ago)

      visit postnhost.articles_path

      expect(page).to have_text("Test Article")
      expect(page).to have_text("Published")
      expect(page).to have_text(default_language.name)
      expect(page).to have_text("Custom excerpt shown on admin index.")
    end

    it "displays scheduled badge and time for scheduled articles" do
      scheduled_time = 2.days.from_now.change(hour: 14, min: 30)
      scheduled_article = create(:article, :scheduled, scheduled_at: scheduled_time, user:, language: default_language)
      draft_article = create(:article, user:, language: default_language)
      published_article = create(:article, :published, user:, language: default_language)

      visit postnhost.articles_path

      expect(page).to have_text(scheduled_article.title)
      expect(page).to have_text("Draft")
      expect(page).to have_text("Scheduled")
      formatted_time = scheduled_time.in_time_zone.strftime("%b %d, %Y at %H:%M %Z")
      expect(page).to have_css(%([title*="#{formatted_time}"]))

      expect(page).to have_text(draft_article.title)
      within(".grid") do
        expect(page).to have_no_css('span[title*="Scheduled for"]', count: 2)
      end

      expect(page).to have_text(published_article.title)
      expect(page).to have_text("Published")
    end

    it "does not show scheduled badge for published articles even if scheduled_at is set" do
      scheduled_article = create(:article, :scheduled, :published, user:, language: default_language)

      visit postnhost.articles_path

      expect(page).to have_text(scheduled_article.title)
      expect(page).to have_text("Published")
      expect(page).to have_no_css('span[title*="Scheduled for"]')
    end

    it "displays empty state when no articles exist" do
      visit postnhost.articles_path

      expect(page).to have_text("No articles yet")
      expect(page).to have_text("Get started by creating your first article.")
      expect(page).to have_link("Create Article", href: postnhost.new_article_path)
    end

    it "filters and sorts articles from the toolbar" do
      published = create(:article, :published, user:, language: default_language, title: "Live Story")
      draft = create(:article, user:, language: default_language, title: "WIP Story")
      scheduled = create(:article, :scheduled, user:, language: default_language, title: "Queued Story")
      published.update_columns(created_at: 3.days.ago)
      draft.update_columns(created_at: 1.day.ago)
      scheduled.update_columns(created_at: 2.days.ago)

      visit postnhost.articles_path

      within('[aria-label="Filter by status"]') { click_link "Draft" }
      expect(page).to have_css('[aria-label="Filter by status"] a.bg-white', text: "Draft")
      expect(page).to have_text(draft.title)
      expect(page).to have_text(scheduled.title)
      expect(page).to have_no_text(published.title)

      within('[aria-label="Filter by status"]') { click_link "Scheduled" }
      expect(page).to have_css('[aria-label="Filter by status"] a.bg-white', text: "Scheduled")
      expect(page).to have_text(scheduled.title)
      expect(page).to have_no_text(draft.title)
      expect(page).to have_no_text(published.title)

      within('[aria-label="Filter by status"]') { click_link "All" }
      expect(page).to have_css('[aria-label="Filter by status"] a.bg-white', text: "All")
      select "Oldest", from: "Sort"
      expect(page).to have_select("Sort", selected: "Oldest")

      expect(page).to have_css("h3", text: published.title)
      expect(page.body.index(published.title)).to be < page.body.index(scheduled.title)
      expect(page.body.index(scheduled.title)).to be < page.body.index(draft.title)
    end

    it "paginates articles" do
      create_list(:article, 16, user:, language: default_language)

      visit postnhost.articles_path

      expect(page).to have_css("nav.flex.items-center.justify-center")

      expect(page).to have_css("a[aria-label='#{I18n.t('postnhost.public.pagination.next')}']")
    end

    it "creates a new article" do
      visit postnhost.articles_path

      click_link "Create Article", match: :first

      expect(page).to have_current_path(%r{/articles/\d+/edit}, url: true)
      expect(Postnhost::Article.count).to eq(1)

      article = Postnhost::Article.last
      expect(article.user).to eq(user)
      expect(article.language).to eq(default_language)
      expect(article).not_to be_published
    end

    it "shows advanced seo fields in editor sidebar" do
      article = create(:article, user:, language: default_language, title: "SEO Fields Article")

      visit postnhost.edit_article_path(article)

      expect(page).to have_field("article[title_tag]", visible: :all)
      expect(page).to have_field("article[og_title]", visible: :all)
      expect(page).to have_field("article[schema_headline]", visible: :all)
      expect(page).to have_field("article[custom_excerpt]", visible: :all)
      expect(page).to have_unchecked_field("article[use_excerpt_as_meta_description]", visible: :all)
    end

    it "navigates to second page" do
      articles = []
      16.times do |index|
        articles << create(:article, user:, language: default_language, created_at: index.minutes.ago)
      end

      newest_article = articles.first
      oldest_article = articles.last

      visit postnhost.articles_path
      expect(page).to have_text(newest_article.title)

      visit postnhost.articles_path(page: 2)

      expect(page).to have_text(oldest_article.title)
      expect(page).to have_no_text(newest_article.title)
    end
  end

  describe "editor code blocks" do
    it "highlights the selected language and stores it in the article content" do
      article = create(
        :article,
        user:,
        language: default_language,
        title: "Code Article",
        content: "<pre><code>const answer = 42</code></pre>"
      )

      visit postnhost.edit_article_path(article)

      within(".sticky") do
        expect(page).to have_no_css('select[aria-label="Code language"]')
      end

      find(".ProseMirror pre").click
      expect(page).to have_css('select[aria-label="Code language"]', visible: :visible)
      language_selector = find('select[aria-label="Code language"]')
      expect(language_selector[:style]).to include("top:", "right:")
      language_selector.select("JavaScript")

      expect(page).to have_css(".ProseMirror code .hljs-keyword", text: "const")

      stored_content = find('input[name="article[content]"]', visible: :all).value
      expect(stored_content).to include('<code class="language-javascript">')
    end
  end

  describe "editor authors manager" do
    it "adds and removes authors from the sidebar section" do
      co_author = create(:user, name: "Ivan", slug: "ivan-author")
      article = create(:article, user:, language: default_language, title: "Author Managed Article")

      visit postnhost.edit_article_path(article)

      click_button "Details" if page.has_no_css?('[data-section-id="authors"]', wait: 1)

      within('[data-section-id="authors"]', visible: :all) do
        click_button "+ Add author"
        find("select").select("Ivan")
        expect(page).to have_css(%([data-author-id="#{co_author.id}"]))
      end

      page.execute_script("document.querySelector('form').requestSubmit()")
      Timeout.timeout(5) do
        loop do
          break if article.reload.authors.include?(co_author)

          sleep 0.1
        end
      end
      expect(article.reload.authors).to include(co_author)

      visit postnhost.edit_article_path(article)
      click_button "Details" if page.has_no_css?('[data-section-id="authors"]', wait: 1)
      within(%([data-author-id="#{co_author.id}"])) do
        find('button[data-action="click->author-manager#removeAuthor"]').click
      end

      page.execute_script("document.querySelector('form').requestSubmit()")
      Timeout.timeout(5) do
        loop do
          break unless article.reload.authors.include?(co_author)

          sleep 0.1
        end
      end
      expect(article.reload.authors).not_to include(co_author)
    end
  end
end

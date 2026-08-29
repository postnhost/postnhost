require "rails_helper"

RSpec.describe "Articles", type: :request do
  let!(:user) { create(:user) }

  before do
    host! "example.com"
    Postnhost::Language.find_or_create_by!(name: "English", html_lang: "en") do |language|
      language.default = true
    end
  end

  describe "GET /articles" do
    it "redirects guests to sign in" do
      get postnhost.articles_path

      expect(response).to redirect_to(postnhost.new_session_path)
    end

    it "returns success for authenticated users" do
      sign_in(user)

      get postnhost.articles_path

      expect(response).to have_http_status(:ok)
    end

    it "filters articles by status" do
      published = create(:article, :published, user:, title: "Published Piece")
      draft = create(:article, user:, title: "Draft Piece")
      scheduled = create(:article, :scheduled, user:, title: "Scheduled Piece")
      sign_in(user)

      get postnhost.articles_path, params: { status: "published" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(published.title)
      expect(response.body).not_to include(draft.title)
      expect(response.body).not_to include(scheduled.title)
    end

    it "sorts articles by created_at ascending" do
      older = create(:article, user:, title: "Older Article")
      newer = create(:article, user:, title: "Newer Article")
      older.update_columns(created_at: 2.days.ago)
      newer.update_columns(created_at: 1.day.ago)
      sign_in(user)

      get postnhost.articles_path, params: { sort: "created_at_asc" }

      expect(response).to have_http_status(:ok)
      expect(response.body.index(older.title)).to be < response.body.index(newer.title)
    end

    it "ignores unknown filter and sort params" do
      create(:article, user:, title: "Safe Article")
      sign_in(user)

      get postnhost.articles_path, params: { status: "archived", sort: "title" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Safe Article")
      expect(response.body).to include('value="created_at_desc" selected')
        .or include('selected="selected" value="created_at_desc"')
    end
  end

  describe "GET /articles/new" do
    it "creates article and redirects to edit page" do
      sign_in(user)

      expect do
        get postnhost.new_article_path
      end.to change(Postnhost::Article, :count).by(1)

      created_article = Postnhost::Article.last
      expect(response).to redirect_to(postnhost.edit_article_path(created_article))
      expect(created_article.authors).to contain_exactly(user)
    end
  end

  describe "PATCH /articles/:id" do
    it "updates article title and redirects" do
      article = create(:article, user:, title: "Old title")
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: "New title", slug: article.slug }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.title).to eq("New title")
    end

    it "updates the Top Picks block flag" do
      article = create(:article, user:, title: "Top Pick Candidate")
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, top_pick: "1" }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.top_pick).to be(true)
    end

    it "parses scheduled_at using configured admin timezone" do
      article = create(:article, user:, title: "Timezoned Article")
      Postnhost::Setting.current.update!(timezone: "Europe/Berlin")
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, scheduled_at: "2026-03-21T14:30" }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.scheduled_at.utc.strftime("%Y-%m-%d %H:%M")).to eq("2026-03-21 13:30")
    end

    it "clears all categories when only an empty category_ids entry is submitted" do
      category = create(:category)
      article = create(:article, user:, title: "Categorized", categories: [category])
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, category_ids: [""] }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.categories).to be_empty
    end

    it "clears suggested articles when only an empty suggested_article_ids entry is submitted" do
      other = create(:article, user:, title: "Other")
      article = create(:article, user:, title: "With suggestions")
      article.suggested_articles << other
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, suggested_article_ids: [""] }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.suggested_articles).to be_empty
    end

    it "updates article authors from author_ids" do
      co_author = create(:user)
      article = create(:article, user:, title: "Collaborative")
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, author_ids: [user.id, co_author.id] }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.authors).to contain_exactly(user, co_author)
    end

    it "clears authors when only an empty author_ids entry is submitted" do
      co_author = create(:user)
      article = create(:article, user:, title: "Bylined")
      article.authors << co_author
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: article.title, slug: article.slug, author_ids: [""] }
      }

      expect(response).to redirect_to(postnhost.articles_path)
      expect(article.reload.authors).to be_empty
    end

    it "renders validation errors and preserves the submitted article" do
      article = create(:article, user:, title: "Valid title")
      sign_in(user)

      patch postnhost.article_path(article), params: {
        article: { title: "Changed title", slug: "INVALID SLUG" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Slug can only contain lowercase letters, numbers, and hyphens")
      expect(article.reload.title).to eq("Valid title")
    end
  end

  describe "PATCH /articles/:id/publish" do
    before { sign_in(user) }

    it "publishes an article and redirects with a notice" do
      article = create(:article, user:)

      patch postnhost.publish_article_path(article)

      expect(response).to redirect_to(postnhost.edit_article_path(article))
      expect(flash[:notice]).to eq("Article has been published.")
      expect(article.reload.published?).to be(true)
    end

    it "renders a Turbo Stream error when publishing fails" do
      article = create(:article, user:)
      article.update_column(:content, nil)

      patch postnhost.publish_article_path(article), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(flash[:alert]).to eq("content can't be blank")
    end
  end

  describe "PATCH /articles/:id/unpublish" do
    before { sign_in(user) }

    it "unpublishes an article and redirects with a notice" do
      article = create(:article, :published, user:)

      patch postnhost.unpublish_article_path(article)

      expect(response).to redirect_to(postnhost.edit_article_path(article))
      expect(flash[:notice]).to eq("Article has been unpublished.")
      expect(article.reload.published?).to be(false)
    end

    it "renders a Turbo Stream error when no publication exists" do
      article = create(:article, user:)

      patch postnhost.unpublish_article_path(article), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:not_found)
      expect(flash[:alert]).to eq("Article snapshot was not found")
    end
  end

  describe "POST /articles/:id/rollback" do
    before { sign_in(user) }

    it "restores the selected version" do
      article = create(:article, user:, title: "Original title")
      version = article.paper_trail.save_with_version
      article.update!(title: "Changed title")

      post postnhost.rollback_article_path(article), params: { version_id: version.id }

      expect(response).to redirect_to(postnhost.edit_article_path(article))
      expect(flash[:notice]).to eq("Article has been rolled back to the selected version.")
      expect(article.reload.title).to eq("Original title")
    end

    it "reports a missing version" do
      article = create(:article, user:)

      post postnhost.rollback_article_path(article), params: { version_id: 0 }

      expect(response).to redirect_to(postnhost.edit_article_path(article))
      expect(flash[:alert]).to eq("Version was not found.")
    end
  end

  describe "GET /articles/:id/versions" do
    it "renders draft history with the publication version first" do
      article = create(:article, user:)
      article.paper_trail.save_with_version
      Postnhost::Publishing::Articles::Publish.call(article:)
      sign_in(user)

      get postnhost.versions_article_path(article)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Version History")
    end
  end

  describe "DELETE /articles/:id" do
    it "destroys the article" do
      article = create(:article, user:)
      sign_in(user)

      expect do
        delete postnhost.article_path(article)
      end.to change(Postnhost::Article, :count).by(-1)

      expect(response).to redirect_to(postnhost.articles_url)
    end
  end

  describe "GET /articles/:id/versions/:version_id/preview" do
    let(:article) { create(:article, user:) }

    before { sign_in(user) }

    it "returns not found when the version does not exist" do
      get postnhost.version_preview_article_path(article, version_id: 0)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found when the version belongs to another article" do
      other_article = create(:article, user:)
      other_version = other_article.paper_trail.save_with_version

      get postnhost.version_preview_article_path(article, version_id: other_version.id)

      expect(response).to have_http_status(:not_found)
    end

    it "renders the selected version" do
      version = article.paper_trail.save_with_version

      get postnhost.version_preview_article_path(article, version_id: version.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Restore This Version")
    end
  end
end

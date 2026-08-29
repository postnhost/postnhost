require "rails_helper"

RSpec.describe "Users", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:user) { create(:user) }

  describe "GET /users" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http ok" do
        get postnhost.users_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get postnhost.users_path
        expect(response).to redirect_to(postnhost.new_session_path)
      end
    end
  end

  describe "GET /users/new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http ok" do
        get postnhost.new_user_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /users/:id/edit" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http ok" do
        get postnhost.edit_user_path(user)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get postnhost.edit_user_path(user)
        expect(response).to redirect_to(postnhost.new_session_path)
      end
    end
  end

  describe "POST /users" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_attributes) do
        {
          name: "New Author",
          email: "new.author@example.com",
          slug: "new-author",
          position: "Editor",
          bio: "Author bio",
          website_url: "https://example.com",
          x_url: "https://x.com/newauthor",
          linkedin_url: "https://linkedin.com/in/newauthor",
          threads_url: "https://threads.net/@newauthor",
          tiktok_url: "https://tiktok.com/@newauthor",
          youtube_url: "https://youtube.com/@newauthor",
          password: "secret123",
          password_confirmation: "secret123"
        }
      end

      it "creates a new author" do
        expect do
          post postnhost.users_path, params: { user: valid_attributes }
        end.to change(Postnhost::User, :count).by(1)
      end

      it "redirects to users index" do
        post postnhost.users_path, params: { user: valid_attributes }
        expect(response).to redirect_to(postnhost.users_path)
      end
    end

    context "with invalid parameters" do
      it "renders a response with 422 status" do
        post postnhost.users_path, params: { user: { name: "", email: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /users/:id" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_attributes) { { name: "Updated Name", email: "newemail@example.com", slug: "updated-name" } }

      it "updates the current user" do
        patch postnhost.user_path(user), params: { user: valid_attributes }
        user.reload
        expect(user.name).to eq("Updated Name")
        expect(user.email).to eq("newemail@example.com")
      end

      it "updates social links when provided" do
        patch postnhost.user_path(user), params: { user: { website_url: "example.com", linkedin_url: "linkedin.com/in/newauthor", instagram_url: "https://instagram.com/newauthor", threads_url: "threads.net/@newauthor", youtube_url: "https://youtube.com/@newauthor" } }
        user.reload

        expect(user.website_url).to eq("example.com")
        expect(user.linkedin_url).to eq("linkedin.com/in/newauthor")
        expect(user.instagram_url).to eq("https://instagram.com/newauthor")
        expect(user.threads_url).to eq("threads.net/@newauthor")
        expect(user.youtube_url).to eq("https://youtube.com/@newauthor")
      end

      it "redirects to the edit page" do
        patch postnhost.user_path(user), params: { user: valid_attributes }
        expect(response).to redirect_to(postnhost.edit_user_path(user))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { email: "" } }

      it "renders a response with 422 status" do
        patch postnhost.user_path(user), params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with password change" do
      let(:password_attributes) { { password: "newpassword", password_confirmation: "newpassword" } }

      it "updates the password when provided" do
        patch postnhost.user_path(user), params: { user: password_attributes }
        user.reload
        expect(user.authenticate("newpassword")).to eq(user)
      end
    end

    context "without password change" do
      let(:no_password_attributes) { { name: "New Name", password: "", password_confirmation: "" } }

      it "ignores blank password fields" do
        original_password_digest = user.password_digest
        patch postnhost.user_path(user), params: { user: no_password_attributes }
        user.reload
        expect(user.password_digest).to eq(original_password_digest)
      end
    end
  end

  describe "DELETE /users/:id" do
    before { sign_in user }

    let!(:removable_user) { create(:user) }

    it "removes author and detaches creator links from articles" do
      article = create(:article, user: removable_user)

      expect do
        delete postnhost.user_path(removable_user)
      end.to change(Postnhost::User, :count).by(-1)

      expect(article.reload.user).to be_nil
      expect(article.authors).to be_empty
      expect(response).to redirect_to(postnhost.users_path)
    end

    it "does not allow deleting current user" do
      delete postnhost.user_path(user)

      expect(response).to redirect_to(postnhost.users_path)
      expect(user.reload).to be_present
    end

    it "does not remove an author who owns a published page" do
      owned_page = create(:page, :published, user: removable_user)

      expect do
        delete postnhost.user_path(removable_user)
      end.not_to change(Postnhost::User, :count)

      expect(response).to redirect_to(postnhost.users_path)
      expect(flash[:alert]).to eq(
        "Author cannot be removed while they own pages. Reassign or remove their pages first."
      )
      expect(owned_page.reload).to be_published
    end
  end

  describe "GET /users/:id/schema_edit" do
    before { sign_in user }

    it "returns http ok" do
      get postnhost.schema_edit_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Author Schema")
    end
  end

  describe "PATCH /users/:id/schema_update" do
    before { sign_in user }

    let!(:german_language) { create(:language, :german) }

    it "stores schema profile and localized schema overrides" do
      patch postnhost.schema_update_user_path(user), params: {
        locale_key: "de",
        schema_profile: {
          same_as: "https://twitter.com/postnhost\nhttps://linkedin.com/in/postnhost\nhttps://facebook.com/postnhost",
          image_url: "https://cdn.example.com/headshot.jpg",
          knows_language: "en\nde",
          alumni_type: "CollegeOrUniversity"
        },
        schema_translations: {
          name: "Autor Name",
          job_title: "Redakteur",
          bio: "Bio in Deutsch",
          knows_about: "SEO\nRails",
          alumni_of: "Berlin University",
          awards: "Best Writer"
        }
      }

      user.reload

      expect(response).to redirect_to(postnhost.schema_edit_user_path(user, locale: "de"))
      expect(user.schema_profile["same_as"]).to eq(
        [
          "https://twitter.com/postnhost",
          "https://linkedin.com/in/postnhost",
          "https://facebook.com/postnhost"
        ]
      )
      expect(user.schema_profile["knows_language"]).to eq(%w[en de])
      expect(user.schema_locale_overrides.dig("de", "name")).to eq("Autor Name")
      expect(user.schema_locale_overrides.dig("de", "knows_about")).to eq("SEO\nRails")
    end
  end
end

require "rails_helper"

RSpec.describe "Languages", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:user) { create(:user) }
  let(:language) { create(:language, :spanish) }

  describe "GET /languages" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get postnhost.languages_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get postnhost.languages_path
        expect(response).to redirect_to(postnhost.new_session_path)
      end
    end
  end

  describe "GET /languages/new" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.new_language_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /languages" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_attributes) { { name: "Spanish", html_lang: "es" } }

      it "creates a new Language" do
        expect do
          post postnhost.languages_path, params: { language: valid_attributes }
        end.to change(Postnhost::Language, :count).by(1)
      end

      it "redirects to the created language" do
        post postnhost.languages_path, params: { language: valid_attributes }
        expect(response).to redirect_to(postnhost.language_path(Postnhost::Language.last))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "", html_lang: "" } }

      it "does not create a new Language" do
        expect do
          post postnhost.languages_path, params: { language: invalid_attributes }
        end.not_to change(Postnhost::Language, :count)
      end

      it "renders a response with 422 status" do
        post postnhost.languages_path, params: { language: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /languages/:id" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.language_path(language)
      expect(response).to have_http_status(:success)
    end

    it "paginates original articles and article variants independently" do
      16.times do |index|
        create(:article, user:, language:, title: "Original Article #{index}", created_at: index.minutes.ago)
      end
      16.times do |index|
        article = create(:article, user:, language: default_language)
        create(:article_variant, article:, language:, title: "Translated Article #{index}", created_at: index.minutes.ago)
      end

      get postnhost.language_path(language)

      expect(response.body).to include("Original Article 0", "Translated Article 0")
      expect(response.body).not_to include("Original Article 15", "Translated Article 15")
      expect(response.body).to include("articles_page=2", "article_variants_page=2")

      get postnhost.language_path(language, articles_page: 2)

      expect(response.body).to include("Original Article 15", "Translated Article 0")
      expect(response.body).not_to include("Original Article 0", "Translated Article 15")

      get postnhost.language_path(language, article_variants_page: 2)

      expect(response.body).to include("Original Article 0", "Translated Article 15")
      expect(response.body).not_to include("Original Article 15", "Translated Article 0")
    end

    context "when no locale YAML exists for the language code" do
      let(:language) { create(:language, name: "Missing", html_lang: "missing", default: false) }

      it "shows the missing locale warning" do
        get postnhost.language_path(language)
        expect(response.body).to include("No locale file for this language code")
        expect(response.body).to include("postnhost:locale missing")
      end
    end
  end

  describe "GET /languages/:id/edit" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.edit_language_path(language)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /languages/:id" do
    before { sign_in user }

    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Language" } }

      it "updates the requested language" do
        patch postnhost.language_path(language), params: { language: new_attributes }
        language.reload
        expect(language.name).to eq("Updated Language")
      end

      it "redirects to the languages list" do
        patch postnhost.language_path(language), params: { language: new_attributes }
        expect(response).to redirect_to(postnhost.languages_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "" } }

      it "renders a response with 422 status" do
        patch postnhost.language_path(language), params: { language: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /languages/:id" do
    before { sign_in user }

    it "destroys the requested language" do
      language
      expect do
        delete postnhost.language_path(language)
      end.to change(Postnhost::Language, :count).by(-1)
    end

    it "redirects to the languages list" do
      delete postnhost.language_path(language)
      expect(response).to redirect_to(postnhost.languages_path)
    end
  end
end

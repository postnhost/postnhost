require "rails_helper"

RSpec.describe "Categories", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:user) { create(:user) }
  let!(:category) { create(:category) }

  describe "GET /categories" do
    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get postnhost.categories_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get postnhost.categories_path
        expect(response).to redirect_to(postnhost.new_session_path)
      end
    end
  end

  describe "GET /categories/new" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.new_category_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /categories" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_attributes) { { name: "New Category", slug: "new-category" } }

      it "creates a new Category" do
        expect do
          post postnhost.categories_path, params: { category: valid_attributes }
        end.to change(Postnhost::Category, :count).by(1)
      end

      it "redirects to the categories index" do
        post postnhost.categories_path, params: { category: valid_attributes }
        expect(response).to redirect_to(postnhost.categories_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "", slug: "" } }

      it "does not create a new Category" do
        expect do
          post postnhost.categories_path, params: { category: invalid_attributes }
        end.not_to change(Postnhost::Category, :count)
      end

      it "renders a response with 422 status" do
        post postnhost.categories_path, params: { category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /categories/:id" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.category_path(category)
      expect(response).to have_http_status(:success)
    end

    it "paginates the category articles" do
      articles = Array.new(16) do |index|
        create(:article, user:, language: default_language, title: "Category Article #{index}", created_at: index.minutes.ago)
      end
      articles.each { |article| article.categories << category }

      get postnhost.category_path(category)

      expect(response.body).to include("Category Article 0")
      expect(response.body).not_to include("Category Article 15")
      expect(response.body).to include("page=2")

      get postnhost.category_path(category, page: 2)

      expect(response.body).to include("Category Article 15")
      expect(response.body).not_to include("Category Article 0")
    end
  end

  describe "GET /categories/:id/edit" do
    before { sign_in user }

    it "returns http success" do
      get postnhost.edit_category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /categories/:id" do
    before { sign_in user }

    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Category" } }

      it "updates the requested category" do
        patch postnhost.category_path(category), params: { category: new_attributes }
        category.reload
        expect(category.name).to eq("Updated Category")
      end

      it "redirects to the category" do
        patch postnhost.category_path(category), params: { category: new_attributes }
        expect(response).to redirect_to(category)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "" } }

      it "renders a response with 422 status" do
        patch postnhost.category_path(category), params: { category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /categories/:id" do
    before { sign_in user }

    it "destroys the requested category" do
      expect do
        delete postnhost.category_path(category)
      end.to change(Postnhost::Category, :count).by(-1)
    end

    it "redirects to the categories list" do
      delete postnhost.category_path(category)
      expect(response).to redirect_to(postnhost.categories_path)
    end
  end
end

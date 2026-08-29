require "rails_helper"

RSpec.describe "CategoryVariants", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:language) { create(:language, :spanish) }
  let!(:variant) { create(:category_variant, category:, language:) }

  before { sign_in user }

  describe "GET /categories/:category_id/category_variants" do
    it "returns http success" do
      get postnhost.category_variants_path(category)
      expect(response).to have_http_status(:success)
    end

    it "does not offer the site default language as a translation target" do
      create(:language, :russian)
      get postnhost.category_variants_path(category)
      expect(response.body).not_to include("language_id=#{default_language.id}")
    end
  end

  describe "GET /categories/:category_id/category_variants/new" do
    it "returns http success" do
      get postnhost.new_category_variant_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /categories/:category_id/category_variants" do
    context "with valid parameters" do
      let(:new_language) { create(:language, :russian) }
      let(:valid_attributes) { { name: "Translated Category", language_id: new_language.id } }

      it "creates a new CategoryVariant" do
        expect do
          post postnhost.category_variants_path(category), params: { category_variant: valid_attributes }
        end.to change(Postnhost::CategoryVariant, :count).by(1)
      end

      it "redirects to the category variants list" do
        post postnhost.category_variants_path(category), params: { category_variant: valid_attributes }
        expect(response).to redirect_to(postnhost.category_variants_path(category))
      end
    end

    context "when language_id is the site default" do
      let(:attributes) { { name: "Duplicate default", language_id: default_language.id } }

      it "does not create a CategoryVariant" do
        expect do
          post postnhost.category_variants_path(category), params: { category_variant: attributes }
        end.not_to change(Postnhost::CategoryVariant, :count)
      end

      it "returns unprocessable response" do
        post postnhost.category_variants_path(category), params: { category_variant: attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "", language_id: language.id } }

      it "does not create a new CategoryVariant" do
        expect do
          post postnhost.category_variants_path(category), params: { category_variant: invalid_attributes }
        end.not_to change(Postnhost::CategoryVariant, :count)
      end

      it "renders a response with 422 status" do
        post postnhost.category_variants_path(category), params: { category_variant: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /categories/:category_id/category_variants/:id/edit" do
    it "returns http success" do
      get postnhost.edit_category_variant_path(category, variant)
      expect(response).to have_http_status(:success)
    end

    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "redirects to the category variants list" do
        get postnhost.edit_category_variant_path(category, variant)
        expect(response).to redirect_to(postnhost.category_variants_path(category))
      end
    end
  end

  describe "PATCH /categories/:category_id/category_variants/:id" do
    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "redirects to the category variants list" do
        patch postnhost.category_variant_path(category, variant), params: { category_variant: { name: "Updated Translation" } }
        expect(response).to redirect_to(postnhost.category_variants_path(category))
      end
    end

    context "with valid parameters" do
      let(:new_attributes) { { name: "Updated Translation" } }

      it "updates the requested variant" do
        patch postnhost.category_variant_path(category, variant), params: { category_variant: new_attributes }
        variant.reload
        expect(variant.name).to eq("Updated Translation")
      end

      it "redirects to the category variants list" do
        patch postnhost.category_variant_path(category, variant), params: { category_variant: new_attributes }
        expect(response).to redirect_to(postnhost.category_variants_path(category))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { name: "" } }

      it "renders a response with 422 status" do
        patch postnhost.category_variant_path(category, variant), params: { category_variant: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /categories/:category_id/category_variants/:id" do
    it "destroys the requested variant" do
      expect do
        delete postnhost.category_variant_path(category, variant)
      end.to change(Postnhost::CategoryVariant, :count).by(-1)
    end

    it "redirects to the category variants list" do
      delete postnhost.category_variant_path(category, variant)
      expect(response).to redirect_to(postnhost.category_variants_path(category))
    end
  end
end

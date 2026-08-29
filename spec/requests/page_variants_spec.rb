require "rails_helper"

RSpec.describe "PageVariants", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:page) { create(:page, user:, language: default_language) }
  let(:language) { create(:language, :spanish) }
  let!(:variant) { create(:page_variant, page:, language:) }

  before { sign_in user }

  describe "GET /pages/:page_id/variants" do
    it "returns http ok" do
      get postnhost.page_variants_path(page)
      expect(response).to have_http_status(:ok)
    end

    context "when the page primary language is not the site default" do
      let(:spanish) { create(:language, :spanish) }
      let(:page) { create(:page, user:, language: spanish) }

      it "lists the default language as an available translation target" do
        get postnhost.page_variants_path(page)
        expect(response.body).to include(default_language.name)
      end
    end
  end

  describe "GET /pages/:page_id/variants/new" do
    let(:new_language) { create(:language, :russian) }

    it "creates a new page variant" do
      expect do
        get postnhost.new_page_variant_path(page, language_id: new_language.id)
      end.to change(Postnhost::PageVariant, :count).by(1)
    end

    it "redirects to edit the new variant" do
      get postnhost.new_page_variant_path(page, language_id: new_language.id)
      new_variant = Postnhost::PageVariant.last
      expect(response).to redirect_to(postnhost.edit_page_variant_path(page, new_variant))
    end
  end

  describe "GET /pages/:page_id/variants/:id/edit" do
    it "returns http ok" do
      get postnhost.edit_page_variant_path(page, variant)
      expect(response).to have_http_status(:ok)
    end

    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "redirects to the translations list" do
        get postnhost.edit_page_variant_path(page, variant)
        expect(response).to redirect_to(postnhost.page_variants_path(page))
      end
    end
  end

  describe "PATCH /pages/:page_id/variants/:id" do
    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "does not update the variant" do
        patch postnhost.page_variant_path(page, variant), params: { page_variant: { title: "Updated Title" } }
        expect(variant.reload.title).not_to eq("Updated Title")
      end

      it "redirects to the translations list" do
        patch postnhost.page_variant_path(page, variant), params: { page_variant: { title: "Updated Title" } }
        expect(response).to redirect_to(postnhost.page_variants_path(page))
      end
    end

    context "with valid parameters" do
      it "updates the requested variant" do
        patch postnhost.page_variant_path(page, variant), params: { page_variant: { title: "Updated Title" } }
        expect(variant.reload.title).to eq("Updated Title")
      end

      it "redirects to the edit page" do
        patch postnhost.page_variant_path(page, variant), params: { page_variant: { title: "Updated Title" } }
        expect(response).to redirect_to(postnhost.edit_page_variant_path(page, variant))
      end
    end
  end

  describe "PATCH /pages/:page_id/variants/:id/publish" do
    before { Postnhost::Publishing::Pages::Publish.call(page:) }

    it "publishes the variant" do
      patch postnhost.publish_page_variant_path(page, variant)
      variant.reload
      expect(variant.published?).to be(true)
      expect(variant.page_variant_snapshot.paper_trail_version).to be_present
    end
  end

  describe "PATCH /pages/:page_id/variants/:id/unpublish" do
    before do
      Postnhost::Publishing::Pages::Publish.call(page:)
      Postnhost::Publishing::PageVariants::Publish.call(page_variant: variant)
    end

    it "unpublishes the variant" do
      patch postnhost.unpublish_page_variant_path(page, variant)
      expect(variant.reload.published?).to be(false)
    end
  end

  describe "DELETE /pages/:page_id/variants/:id" do
    it "destroys the requested variant" do
      expect do
        delete postnhost.page_variant_path(page, variant)
      end.to change(Postnhost::PageVariant, :count).by(-1)
    end

    it "redirects to the variants list" do
      delete postnhost.page_variant_path(page, variant)
      expect(response).to redirect_to(postnhost.page_variants_path(page))
    end
  end

  describe "PATCH /pages/:page_id/variants/bulk_publish" do
    let!(:variant2) { create(:page_variant, page:, language: create(:language, :russian)) }

    before { Postnhost::Publishing::Pages::Publish.call(page:) }

    it "publishes multiple variants" do
      patch postnhost.bulk_publish_page_variants_path(page), params: { ids: [variant.id, variant2.id] }
      expect(variant.reload.published?).to be(true)
      expect(variant2.reload.published?).to be(true)
    end

    it "redirects without a flash message" do
      patch postnhost.bulk_publish_page_variants_path(page), params: { ids: [variant.id] }
      expect(response).to redirect_to(postnhost.page_variants_path(page))
      expect(flash).to be_empty
    end
  end

  describe "PATCH /pages/:page_id/variants/bulk_unpublish" do
    before do
      Postnhost::Publishing::Pages::Publish.call(page:)
      Postnhost::Publishing::PageVariants::Publish.call(page_variant: variant)
    end

    it "unpublishes multiple variants" do
      patch postnhost.bulk_unpublish_page_variants_path(page), params: { ids: [variant.id] }
      expect(variant.reload.published?).to be(false)
    end
  end

  describe "DELETE /pages/:page_id/variants/bulk_destroy" do
    let!(:variant2) { create(:page_variant, page:, language: create(:language, :russian)) }

    it "destroys multiple variants" do
      expect do
        delete postnhost.bulk_destroy_page_variants_path(page), params: { ids: [variant.id, variant2.id] }
      end.to change(Postnhost::PageVariant, :count).by(-2)
    end
  end
end

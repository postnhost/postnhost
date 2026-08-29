require "rails_helper"

RSpec.describe "ArticleVariants", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user:) }
  let(:language) { create(:language, :spanish) }
  let!(:variant) { create(:article_variant, article:, language:) }

  before { sign_in user }

  describe "GET /articles/:article_id/article_variants" do
    it "returns http ok" do
      get postnhost.article_variants_path(article)
      expect(response).to have_http_status(:ok)
    end

    context "when the article primary language is not the site default" do
      let!(:english) { default_language }
      let!(:spanish) { create(:language, :spanish) }
      let(:article) { create(:article, user:, language: spanish) }

      it "lists the default language as an available translation target" do
        get postnhost.article_variants_path(article)
        expect(response.body).to include(english.name)
      end
    end
  end

  describe "GET /articles/:article_id/article_variants/new" do
    let(:new_language) { create(:language, :russian) }

    it "creates a new article variant" do
      expect do
        get postnhost.new_article_variant_path(article, language_id: new_language.id)
      end.to change(Postnhost::ArticleVariant, :count).by(1)
    end

    it "redirects to edit the new variant" do
      get postnhost.new_article_variant_path(article, language_id: new_language.id)
      new_variant = Postnhost::ArticleVariant.last
      expect(response).to redirect_to(postnhost.edit_article_variant_path(article, new_variant))
    end
  end

  describe "GET /articles/:article_id/article_variants/:id/edit" do
    it "returns http ok" do
      get postnhost.edit_article_variant_path(article, variant)
      expect(response).to have_http_status(:ok)
    end

    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "redirects to the translations list" do
        get postnhost.edit_article_variant_path(article, variant)
        expect(response).to redirect_to(postnhost.article_variants_path(article))
      end
    end
  end

  describe "PATCH /articles/:article_id/article_variants/:id" do
    context "when the variant is still generating (AI translation in progress)" do
      before { variant.update!(generating: true) }

      it "does not update the variant" do
        patch postnhost.article_variant_path(article, variant), params: { article_variant: { title: "Updated Title" } }
        expect(variant.reload.title).not_to eq("Updated Title")
      end

      it "redirects to the translations list" do
        patch postnhost.article_variant_path(article, variant), params: { article_variant: { title: "Updated Title" } }
        expect(response).to redirect_to(postnhost.article_variants_path(article))
      end
    end

    context "with valid parameters" do
      let(:new_attributes) { { title: "Updated Title" } }

      it "updates the requested variant" do
        patch postnhost.article_variant_path(article, variant), params: { article_variant: new_attributes }
        variant.reload
        expect(variant.title).to eq("Updated Title")
      end

      it "redirects to the edit page" do
        patch postnhost.article_variant_path(article, variant), params: { article_variant: new_attributes }
        expect(response).to redirect_to(postnhost.edit_article_variant_path(article, variant))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { { title: "" } }

      it "redirects to edit page" do
        patch postnhost.article_variant_path(article, variant), params: { article_variant: invalid_attributes }
        expect(response).to redirect_to(postnhost.edit_article_variant_path(article, variant))
      end
    end
  end

  describe "PATCH /articles/:article_id/article_variants/:id/publish" do
    before { Postnhost::Publishing::Articles::Publish.call(article:) }

    it "publishes the variant" do
      patch postnhost.publish_article_variant_path(article, variant)
      variant.reload
      expect(variant.published?).to be(true)
      expect(variant.article_variant_snapshot.paper_trail_version).to be_present
    end

    it "redirects without a flash message" do
      patch postnhost.publish_article_variant_path(article, variant)

      expect(response).to redirect_to(postnhost.edit_article_variant_path(article, variant))
      expect(flash).to be_empty
    end

    it "renders a Turbo Stream without a flash message" do
      patch postnhost.publish_article_variant_path(article, variant),
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(flash).to be_empty
    end
  end

  describe "PATCH /articles/:article_id/article_variants/:id/unpublish" do
    before do
      Postnhost::Publishing::Articles::Publish.call(article:)
      Postnhost::Publishing::ArticleVariants::Publish.call(article_variant: variant)
    end

    it "unpublishes the variant" do
      patch postnhost.unpublish_article_variant_path(article, variant)
      variant.reload
      expect(variant.published?).to be(false)
    end

    it "redirects without a flash message" do
      patch postnhost.unpublish_article_variant_path(article, variant)

      expect(response).to redirect_to(postnhost.edit_article_variant_path(article, variant))
      expect(flash).to be_empty
    end
  end

  describe "DELETE /articles/:article_id/article_variants/:id" do
    it "destroys the requested variant" do
      expect do
        delete postnhost.article_variant_path(article, variant)
      end.to change(Postnhost::ArticleVariant, :count).by(-1)
    end

    it "redirects to the variants list" do
      delete postnhost.article_variant_path(article, variant)
      expect(response).to redirect_to(postnhost.article_variants_path(article))
    end
  end

  describe "PATCH /articles/:article_id/article_variants/bulk_publish" do
    let!(:variant2) { create(:article_variant, article:) }

    before { Postnhost::Publishing::Articles::Publish.call(article:) }

    it "publishes multiple variants" do
      patch postnhost.bulk_publish_article_variants_path(article), params: { ids: [variant.id, variant2.id] }
      expect(variant.reload.published?).to be(true)
      expect(variant2.reload.published?).to be(true)
    end

    it "redirects without a flash message" do
      patch postnhost.bulk_publish_article_variants_path(article), params: { ids: [variant.id] }
      expect(response).to redirect_to(postnhost.article_variants_path(article))
      expect(flash).to be_empty
    end
  end

  describe "PATCH /articles/:article_id/article_variants/bulk_unpublish" do
    before do
      Postnhost::Publishing::Articles::Publish.call(article:)
      Postnhost::Publishing::ArticleVariants::Publish.call(article_variant: variant)
    end

    it "unpublishes multiple variants" do
      patch postnhost.bulk_unpublish_article_variants_path(article), params: { ids: [variant.id] }
      expect(variant.reload.published?).to be(false)
    end
  end

  describe "DELETE /articles/:article_id/article_variants/bulk_destroy" do
    let!(:variant2) { create(:article_variant, article:) }

    it "destroys multiple variants" do
      expect do
        delete postnhost.bulk_destroy_article_variants_path(article), params: { ids: [variant.id, variant2.id] }
      end.to change(Postnhost::ArticleVariant, :count).by(-2)
    end
  end
end

require "rails_helper"

RSpec.describe "Articles::Translations", type: :request do
  include ActiveJob::TestHelper

  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user:, language: default_language) }
  let(:russian) { create(:language, :russian) }

  before { sign_in user }

  describe "POST /articles/:article_id/translations" do
    it "enqueues translation and creates a generating variant" do
      expect do
        post postnhost.article_translations_path(article), params: { language_ids: [russian.id.to_s] }
      end.to have_enqueued_job(Postnhost::Translation::ArticleVariantJob).with(article.id, russian.id)
                                                                         .and change(Postnhost::ArticleVariant, :count).by(1)

      expect(response).to redirect_to(postnhost.article_variants_path(article))
      expect(Postnhost::ArticleVariant.find_by!(article:, language: russian).generating).to be(true)
    end

    it "accepts an empty selection without enqueueing work" do
      expect do
        post postnhost.article_translations_path(article)
      end.not_to have_enqueued_job(Postnhost::Translation::ArticleVariantJob)

      expect(response).to redirect_to(postnhost.article_variants_path(article))
      expect(article.article_variants).to be_empty
    end

    it "returns not found when the article does not exist" do
      post postnhost.article_translations_path(article_id: 0), params: { language_ids: [russian.id.to_s] }

      expect(response).to have_http_status(:not_found)
      expect(enqueued_jobs).to be_empty
    end
  end
end

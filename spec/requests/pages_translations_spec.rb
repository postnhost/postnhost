require "rails_helper"

RSpec.describe "Pages::Translations", type: :request do
  include ActiveJob::TestHelper

  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:page) { create(:page, user:, language: default_language) }
  let(:russian) { create(:language, :russian) }

  before { sign_in user }

  describe "POST /pages/:page_id/translations" do
    it "enqueues the page translation job and creates a generating page variant" do
      expect do
        post postnhost.page_translations_path(page), params: { language_ids: [russian.id.to_s] }
      end.to have_enqueued_job(Postnhost::Translation::PageVariantJob).with(page.id, russian.id)
                                                                      .and change(Postnhost::PageVariant, :count).by(1)

      expect(response).to redirect_to(postnhost.page_variants_path(page))

      variant = Postnhost::PageVariant.find_by!(page: page, language: russian)
      expect(variant.generating).to be(true)
      expect(variant.title).to be_nil
    end

    it "returns not found when the page does not exist" do
      post postnhost.page_translations_path(page_id: 0), params: { language_ids: [russian.id.to_s] }

      expect(response).to have_http_status(:not_found)
      expect(enqueued_jobs).to be_empty
    end
  end
end

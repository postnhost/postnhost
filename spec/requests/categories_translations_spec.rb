require "rails_helper"

RSpec.describe "Categories::Translations", type: :request do
  include ActiveJob::TestHelper

  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:russian) { create(:language, :russian) }

  before { sign_in user }

  describe "POST /categories/:category_id/translations" do
    it "enqueues the category translation job and creates a generating category variant" do
      expect do
        post postnhost.category_translations_path(category), params: { language_ids: [russian.id.to_s] }
      end.to have_enqueued_job(Postnhost::Translation::CategoryVariantJob).with(category.id, russian.id)
                                                                          .and change(Postnhost::CategoryVariant, :count).by(1)

      expect(response).to redirect_to(postnhost.category_variants_path(category))

      variant = Postnhost::CategoryVariant.find_by!(category: category, language: russian)
      expect(variant.generating).to be(true)
      expect(variant.name).to be_nil
    end
  end
end

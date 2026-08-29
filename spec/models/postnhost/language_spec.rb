require "rails_helper"

RSpec.describe Postnhost::Language, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:html_lang) }
    it { is_expected.to validate_uniqueness_of(:html_lang) }
  end

  describe "associations" do
    it { is_expected.to have_many(:articles).dependent(:nullify) }
    it { is_expected.to have_many(:article_variants).dependent(:destroy) }
    it { is_expected.to have_many(:category_variants).dependent(:destroy) }
  end

  describe "callbacks" do
    let(:language) { create(:language, :default) }
    let(:article) { create(:article, language:) }

    it "touches associated articles after save when name changes" do
      original_time = article.updated_at
      travel(1.second) do
        language.update!(name: "New Name")
        expect(article.reload.updated_at).to be > original_time
      end
    end

    it "touches associated articles after save when html_lang changes" do
      original_time = article.updated_at
      travel(1.second) do
        language.update!(html_lang: "new-lang")
        expect(article.reload.updated_at).to be > original_time
      end
    end

    it "nullifies associated records when destroyed" do
      expect { language.destroy! }.to change { article.reload.language_id }.to(nil)
    end
  end
end

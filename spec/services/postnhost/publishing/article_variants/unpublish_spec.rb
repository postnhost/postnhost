require "rails_helper"

RSpec.describe Postnhost::Publishing::ArticleVariants::Unpublish, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "removes an article variant snapshot" do
    article = create(:article, :published, language: default_language)
    variant = create(:article_variant, :published, article:, language: spanish)

    result = described_class.call(article_variant: variant)

    expect(result).to be_success
    expect(variant.reload.article_variant_snapshot).to be_nil
  end
end

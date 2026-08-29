require "rails_helper"

RSpec.describe Postnhost::Publishing::ArticleVariants::Publish, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "publishes an article variant" do
    article = create(:article, :published, language: default_language)
    variant = create(:article_variant, article:, language: spanish)

    result = described_class.call(article_variant: variant)

    expect(result).to be_success
    expect(result.value).to be_a(Postnhost::Snapshot::ArticleVariant)
    expect(variant.reload.article_variant_snapshot).to eq(result.value)
  end
end

require "rails_helper"

RSpec.describe Postnhost::Publishing::ArticleVariants::UnpublishMany, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "unpublishes selected variants" do
    article = create(:article, :published, language: default_language)
    spanish = create(:article_variant, :published, article:, language: create(:language, :spanish))
    german = create(:article_variant, :published, article:, language: create(:language, :german))

    result = described_class.call(article:, ids: [spanish.id, german.id])

    expect(result).to be_success
    expect(article.article_variants.joins(:article_variant_snapshot)).to be_empty
  end
end

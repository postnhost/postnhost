require "rails_helper"

RSpec.describe Postnhost::Publishing::ArticleVariants::PublishMany, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "publishes selected variants" do
    article = create(:article, :published, language: default_language)
    spanish = create(:article_variant, article:, language: create(:language, :spanish))
    german = create(:article_variant, article:, language: create(:language, :german))

    result = described_class.call(article:, ids: [spanish.id, german.id])

    expect(result).to be_success
    expect(result.value[:successes]).to contain_exactly(spanish, german)
    expect(article.article_variants.joins(:article_variant_snapshot).count).to eq(2)
  end
end

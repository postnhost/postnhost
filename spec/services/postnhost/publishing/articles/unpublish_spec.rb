require "rails_helper"

RSpec.describe Postnhost::Publishing::Articles::Unpublish, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "removes the article snapshot" do
    article = create(:article, :published, language: default_language)

    result = described_class.call(article:)

    expect(result).to be_success
    expect(article.reload.article_snapshot).to be_nil
  end

  it "fails when no snapshot exists" do
    result = described_class.call(article: create(:article, language: default_language))

    expect(result).not_to be_success
    expect(result.status).to eq(:not_found)
  end
end

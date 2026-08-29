require "rails_helper"

RSpec.describe Postnhost::Publishing::Versions::RestoreDraft, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "restores the draft attributes from its version" do
    article = create(:article, language: default_language, title: "Original title")
    version = article.paper_trail.save_with_version
    article.update_column(:title, "Changed title")

    result = described_class.call(record: article, version:)

    expect(result).to be_success
    expect(article.reload.title).to eq("Original title")
  end

  it "rejects a version from another record" do
    article = create(:article, language: default_language)
    other = create(:article, language: default_language)
    version = other.paper_trail.save_with_version

    result = described_class.call(record: article, version:)

    expect(result).not_to be_success
  end
end

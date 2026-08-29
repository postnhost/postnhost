require "rails_helper"

RSpec.describe Postnhost::Publishing::ArticleVariants::SnapshotWriter, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "writes an article variant snapshot" do
    article = create(:article, :published, language: default_language)
    variant = create(:article_variant, article:, language: spanish)

    snapshot = described_class.new(variant:).call

    expect(snapshot).to be_a(Postnhost::Snapshot::ArticleVariant)
    expect(snapshot.title).to eq(variant.title)
    expect(snapshot.article_snapshot).to eq(article.article_snapshot)
  end

  it "reports invalid and unfinished translations" do
    article = create(:article, language: default_language)
    variant = create(:article_variant, article:, language: spanish)
    variant.update_columns(title: nil, content: nil, generating: true)

    expect do
      described_class.new(variant:).call
    end.to raise_error(Postnhost::Publishing::Error) { |error|
      expect(error.messages).to contain_exactly(
        "base article must be published",
        "title can't be blank",
        "content can't be blank",
        "translation is still being generated"
      )
    }
  end
end

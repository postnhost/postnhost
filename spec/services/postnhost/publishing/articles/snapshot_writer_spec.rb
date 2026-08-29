require "rails_helper"

RSpec.describe Postnhost::Publishing::Articles::SnapshotWriter, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "writes the public snapshot" do
    article = create(:article, language: default_language)

    snapshot = described_class.new(article:).call

    expect(snapshot).to be_a(Postnhost::Snapshot::Article)
    expect(snapshot.title).to eq(article.title)
  end

  it "mirrors categories, authors, and suggestions onto the snapshot" do
    article = create(:article, language: default_language)
    categories = create_list(:category, 2)
    categories.each { |category| create(:article_category, article:, category:) }
    coauthor = create(:user)
    create(:article_author, article:, user: coauthor, position: 5)
    suggested = create(:article, language: default_language)
    create(:article_suggestion, article:, suggested_article: suggested, position: 0)

    snapshot = described_class.new(article:).call

    expect(snapshot.category_ids).to match_array(categories.map(&:id))
    expect(snapshot.article_snapshot_authors.map(&:position)).to eq((0...snapshot.article_snapshot_authors.size).to_a)
    expect(snapshot.article_snapshot_authors.map(&:user_id)).to include(coauthor.id)
    expect(snapshot.article_snapshot_suggestions.map(&:suggested_article_id)).to eq([suggested.id])
  end

  it "removes join rows that the draft no longer references" do
    article = create(:article, language: default_language)
    category = create(:category)
    join = create(:article_category, article:, category:)
    described_class.new(article:).call

    join.destroy!
    snapshot = described_class.new(article: article.reload).call

    expect(snapshot.category_ids).to be_empty
  end

  it "reports every missing publication requirement" do
    article = create(:article, language: default_language)
    article.update_columns(title: nil, content: nil, slug: nil, language_id: nil)

    expect do
      described_class.new(article:).call
    end.to raise_error(Postnhost::Publishing::Error) { |error|
      expect(error.messages).to contain_exactly(
        "title can't be blank",
        "content can't be blank",
        "slug can't be blank",
        "language must exist"
      )
    }
  end

  it "fails when PaperTrail cannot persist the publication source" do
    article = create(:article, language: default_language)
    paper_trail = article.paper_trail
    allow(article).to receive(:paper_trail).and_return(paper_trail)
    allow(paper_trail).to receive(:save_with_version).and_return(nil)

    expect do
      described_class.new(article:).call
    end.to raise_error(Postnhost::Publishing::Error, "could not capture the snapshot source version")
  end
end

require "rails_helper"

RSpec.describe Postnhost::Publishing::Articles::Publish, type: :service do
  let!(:default_language) { create(:language, :default) }
  let(:article) { create(:article, language: default_language) }

  it "atomically snapshots fields, relationships, source version, and revision" do
    category = create(:category)
    author = create(:user)
    suggestion = create(:article, :published, language: default_language)
    article.categories << category
    article.article_authors.destroy_all
    create(:article_author, article:, user: author, position: 1)
    create(:article_suggestion, article:, suggested_article: suggestion, position: 1)
    revision = Postnhost::PublicSiteRevision.current.revision

    result = described_class.call(article:)

    expect(result).to be_success
    snapshot = result.value
    expect(snapshot.attributes.slice("title", "content", "slug")).to eq(article.attributes.slice("title", "content", "slug"))
    expect(snapshot.paper_trail_version).to be_a(Postnhost::Version)
    expect(snapshot.category_ids).to eq([category.id])
    expect(snapshot.authors).to eq([author])
    expect(snapshot.article_snapshot_suggestions.pluck(:suggested_article_id)).to eq([suggestion.id])
    expect(Postnhost::PublicSiteRevision.current.revision).to eq(revision + 1)
  end

  it "preserves first snapshot time and replaces the snapshot on republish" do
    first = described_class.call(article:).value
    first_published_at = first.published_at
    first_updated_at = first.updated_at
    travel 1.minute
    article.update!(title: "Republished title")

    second = described_class.call(article:).value

    expect(second.id).to eq(first.id)
    expect(second.title).to eq("Republished title")
    expect(second.published_at).to eq(first_published_at)
    expect(second.updated_at).to be > first_updated_at
  end

  it "rolls back the entire transition when a publish-time route conflict exists" do
    create(:page, :published, language: default_language, slug: "conflict")
    article.slug = "conflict"
    article.save!(validate: false)
    revision = Postnhost::PublicSiteRevision.current.revision

    result = described_class.call(article:)

    expect(result).not_to be_success
    expect(article.reload.article_snapshot).to be_nil
    expect(Postnhost::PublicSiteRevision.current.revision).to eq(revision)
  end
end

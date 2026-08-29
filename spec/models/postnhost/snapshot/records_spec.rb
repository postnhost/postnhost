require "rails_helper"

RSpec.describe "Snapshot records", type: :model do
  let!(:default_language) { create(:language, :default) }

  it "uses the engine-specific PaperTrail version class" do
    article = create(:article, language: default_language)

    version = article.paper_trail.save_with_version

    expect(version).to be_a(Postnhost::Version)
    expect(Postnhost::Version.table_name).to eq("postnhost_versions")
    expect(PaperTrail::Version.table_name).to eq("versions")
  end

  it "compares scalar and relationship draft changes against an article snapshot" do
    article = create(:article, :published, language: default_language)
    category = create(:category)
    article.categories << category

    expect(article.reload.unpublished_changes?).to be(true)

    result = Postnhost::Publishing::Articles::Publish.call(article:)

    expect(result).to be_success
    expect(article.reload.unpublished_changes?).to be(false)
    expect(article.article_snapshot.category_ids).to contain_exactly(category.id)
  end

  it "keeps a variant snapshot stored but gates visibility through the parent snapshot" do
    spanish = create(:language, :spanish)
    article = create(:article, :published, language: default_language)
    variant = create(:article_variant, :published, article:, language: spanish)

    Postnhost::Publishing::Articles::Unpublish.call(article:)

    expect(variant.reload.article_variant_snapshot).to be_present
    expect(Postnhost::Snapshot::ArticleVariant.joins(:article_snapshot)).to be_empty
  end
end

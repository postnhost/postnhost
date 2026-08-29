require "rails_helper"

RSpec.describe Postnhost::Publishing::BulkTransition, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "runs the command for selected records" do
    article = create(:article, :published, language: default_language)
    variant = create(:article_variant, article:, language: create(:language, :spanish))

    result = described_class.call(
      scope: article.article_variants,
      ids: [variant.id],
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(result).to be_success
    expect(result.value[:successes]).to eq([variant])
  end

  it "rejects an empty selection" do
    result = described_class.call(
      scope: Postnhost::ArticleVariant.all,
      ids: [],
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(result).not_to be_success
  end

  it "returns successes alongside missing and failed records" do
    article = create(:article, :published, language: default_language)
    spanish = create(:language, :spanish)
    successful = create(:article_variant, article:, language: spanish)
    failed = create(:article_variant, article:, language: create(:language, :german), generating: true)

    result = described_class.call(
      scope: article.article_variants,
      ids: [successful.id, failed.id, 999_999],
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(result).to be_success
    expect(result.status).to eq(:unprocessable_content)
    expect(result.value[:successes]).to eq([successful])
    expect(result.value[:failures].keys).to contain_exactly(failed.id, 999_999)
  end

  it "bumps the public site revision once for the whole batch" do
    article = create(:article, :published, language: default_language)
    variants = [create(:language, :spanish), create(:language, :german)].map do |language|
      create(:article_variant, article:, language:)
    end
    revision = Postnhost::PublicSiteRevision.current.revision

    described_class.call(
      scope: article.article_variants,
      ids: variants.map(&:id),
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(Postnhost::PublicSiteRevision.current.revision).to eq(revision + 1)
  end

  it "keeps a failed record from rolling back the records that succeeded" do
    article = create(:article, :published, language: default_language)
    successful = create(:article_variant, article:, language: create(:language, :spanish))
    failed = create(:article_variant, article:, language: create(:language, :german), generating: true)

    described_class.call(
      scope: article.article_variants,
      ids: [successful.id, failed.id],
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(successful.reload.published?).to be(true)
    expect(failed.reload.published?).to be(false)
  end

  it "rejects non-integer IDs" do
    result = described_class.call(
      scope: Postnhost::ArticleVariant.all,
      ids: ["not-an-id"],
      service_class: Postnhost::Publishing::ArticleVariants::Publish,
      argument_name: :article_variant
    )

    expect(result).not_to be_success
    expect(result.errors).to eq(["Translation IDs must be integers"])
  end
end

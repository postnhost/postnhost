FactoryBot.define do
  factory :article_variant_snapshot, class: "Postnhost::Snapshot::ArticleVariant" do
    article_variant
    article { article_variant.article }
    language { article_variant.language }
    paper_trail_version { article_variant.paper_trail.save_with_version }
    title { article_variant.title }
    content { article_variant.content }
    published_at { Time.current }
  end
end

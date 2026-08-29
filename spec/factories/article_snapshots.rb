FactoryBot.define do
  factory :article_snapshot, class: "Postnhost::Snapshot::Article" do
    article
    language { article.language }
    paper_trail_version { article.paper_trail.save_with_version }
    title { article.title }
    title_tag { article.title_tag }
    meta_description { article.meta_description }
    content { article.content }
    slug { article.slug }
    published_at { Time.current }
  end
end

FactoryBot.define do
  factory :article_category, class: "Postnhost::ArticleCategory" do
    article
    category
  end
end

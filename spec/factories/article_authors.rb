FactoryBot.define do
  factory :article_author, class: "Postnhost::ArticleAuthor" do
    article
    user
    sequence(:position) { |n| n }
  end
end

FactoryBot.define do
  factory :article_suggestion, class: "Postnhost::ArticleSuggestion" do
    article
    suggested_article { association :article }
    sequence(:position) { |n| n }
  end
end

FactoryBot.define do
  factory :category, class: "Postnhost::Category" do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    meta_description { Faker::Lorem.sentence(word_count: 8) }
  end
end

FactoryBot.define do
  factory :category_variant, class: "Postnhost::CategoryVariant" do
    category
    language factory: %i[language spanish]
    generating { false }
    sequence(:name) { |n| "Category Variant #{n}" }
    meta_description { Faker::Lorem.sentence(word_count: 10) }
  end
end

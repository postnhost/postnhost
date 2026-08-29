FactoryBot.define do
  factory :page, class: "Postnhost::Page" do
    user
    language

    sequence(:title) { |n| "Page Title #{n}" }
    sequence(:slug) { |n| "page-title-#{n}" }
    title_tag { Faker::Lorem.sentence(word_count: 6) }
    meta_description { Faker::Lorem.sentence(word_count: 12) }
    content { "<p>Example page content</p>" }
    trait :published do
      after(:create) do |page|
        result = Postnhost::Publishing::Pages::Publish.call(page:)
        raise result.errors.to_sentence unless result.success?

        page.reload
      end
    end
  end
end

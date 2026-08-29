FactoryBot.define do
  factory :article, class: "Postnhost::Article" do
    user
    language

    sequence(:title) { |n| "Article Title #{n}" }
    sequence(:slug) { |n| "article-title-#{n}" }
    title_tag { Faker::Lorem.sentence(word_count: 6) }
    meta_description { Faker::Lorem.sentence(word_count: 12) }
    content { "<p>Example content</p>" }
    cover_image_alt { "Cover image alt text" }
    top_pick { false }
    scheduled_at { nil }
    scheduled_job_id { nil }

    trait :published do
      after(:create) do |article|
        result = Postnhost::Publishing::Articles::Publish.call(article:)
        raise result.errors.to_sentence unless result.success?

        article.reload
      end
    end

    trait :with_content do
      content { "<h2>Heading</h2><p>#{Faker::Lorem.paragraph}</p>" }
    end

    trait :scheduled do
      scheduled_at { 1.hour.from_now }
      scheduled_job_id { SecureRandom.uuid }
    end

    trait :without_user do
      user { nil }
    end
  end
end

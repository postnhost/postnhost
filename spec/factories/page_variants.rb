FactoryBot.define do
  factory :page_variant, class: "Postnhost::PageVariant" do
    page
    language

    sequence(:title) { |n| "Page Variant #{n}" }
    title_tag { Faker::Lorem.sentence(word_count: 6) }
    meta_description { Faker::Lorem.sentence(word_count: 10) }
    content { "<p>Translated content</p>" }
    generating { false }

    trait :published do
      after(:create) do |variant|
        unless variant.page.published?
          page_result = Postnhost::Publishing::Pages::Publish.call(page: variant.page)
          raise page_result.errors.to_sentence unless page_result.success?
        end

        result = Postnhost::Publishing::PageVariants::Publish.call(page_variant: variant)
        raise result.errors.to_sentence unless result.success?

        variant.reload
      end
    end
  end
end

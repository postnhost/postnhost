FactoryBot.define do
  factory :article_variant, class: "Postnhost::ArticleVariant" do
    article
    language

    sequence(:title) { |n| "Article Variant #{n}" }
    title_tag { Faker::Lorem.sentence(word_count: 6) }
    meta_description { Faker::Lorem.sentence(word_count: 10) }
    content { "<p>Translated content</p>" }
    generating { false }

    trait :published do
      after(:create) do |variant|
        unless variant.article.published?
          article_result = Postnhost::Publishing::Articles::Publish.call(article: variant.article)
          raise article_result.errors.to_sentence unless article_result.success?
        end

        result = Postnhost::Publishing::ArticleVariants::Publish.call(article_variant: variant)
        raise result.errors.to_sentence unless result.success?

        variant.reload
      end
    end
  end
end

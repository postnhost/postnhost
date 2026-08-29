FactoryBot.define do
  factory :language, class: "Postnhost::Language" do
    name { "English" }
    html_lang { "en" }
    default { true }

    initialize_with { Postnhost::Language.find_or_initialize_by(html_lang:) }

    trait :default do
      name { "English" }
      html_lang { "en" }
      default { true }
    end

    trait :spanish do
      name { "Spanish" }
      html_lang { "es" }
      default { false }
    end

    trait :russian do
      name { "Russian" }
      html_lang { "ru" }
      default { false }
    end

    trait :german do
      name { "German" }
      html_lang { "de" }
      default { false }
    end
  end
end

FactoryBot.define do
  factory :user, class: "Postnhost::User" do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "Author #{n}" }
    sequence(:slug) { |n| "author-#{n}" }
    position { "Editor" }
    bio { "Short author bio." }
    password { "password" }
    password_confirmation { "password" }
  end
end

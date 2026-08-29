FactoryBot.define do
  factory :template, class: "Postnhost::Template" do
    name { Postnhost::Template::DEFAULT_NAME }
  end
end

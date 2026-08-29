FactoryBot.define do
  factory :navigation_item, class: "Postnhost::NavigationItem" do
    navigation
    container_kind { "header" }
    kind { "link" }
    target_kind { "external" }
    url { "https://example.com" }
    label_translations { { "en" => "Example" } }
    position { 0 }
    nofollow { false }
  end
end

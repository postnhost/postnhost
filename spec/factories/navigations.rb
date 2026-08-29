FactoryBot.define do
  factory :navigation, class: "Postnhost::Navigation" do
    setting { Postnhost::Setting.current }
  end
end

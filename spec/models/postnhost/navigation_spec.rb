require "rails_helper"

RSpec.describe Postnhost::Navigation, type: :model do
  let!(:default_language) { create(:language, :default) }

  it "enforces one navigation per setting" do
    setting = Postnhost::Setting.current
    create(:navigation, setting: setting)

    duplicate = build(:navigation, setting: setting)

    expect(duplicate).not_to be_valid
  end

  it "replaces tree while preserving non-edited locale labels" do
    navigation = create(:navigation)
    item = create(:navigation_item, navigation: navigation, label_translations: { "en" => "Home", "es" => "Inicio" })

    navigation.replace_tree!(tree: {
                               "header" => [{ "id" => item.id, "kind" => "link", "target_kind" => "external", "url" => "https://example.com", "label" => "Homepage" }],
                               "footer" => []
                             }, locale_key: "en")

    saved = navigation.reload.navigation_items.first
    expect(saved.label_translations["en"]).to eq("Homepage")
    expect(saved.label_translations["es"]).to eq("Inicio")
  end

  it "bumps the public site revision once after replacing the tree" do
    navigation = create(:navigation)
    revision = Postnhost::PublicSiteRevision.current.revision

    navigation.replace_tree!(tree: {
                               "header" => [{ "kind" => "link", "target_kind" => "external", "url" => "https://example.com", "label" => "Example" }],
                               "footer" => []
                             }, locale_key: "en")

    expect(Postnhost::PublicSiteRevision.current.revision).to eq(revision + 1)
  end
end

require "rails_helper"

RSpec.describe Postnhost::NavigationItem, type: :model do
  let!(:default_language) { create(:language, :default) }

  it "requires header root kind to be link/dropdown" do
    item = build(:navigation_item, container_kind: "header", kind: "column")

    expect(item).not_to be_valid
    expect(item.errors[:kind]).to include("must be link or dropdown for header root")
  end

  it "requires footer root kind to be column" do
    item = build(:navigation_item, container_kind: "footer", kind: "link")

    expect(item).not_to be_valid
    expect(item.errors[:kind]).to include("must be column for footer root")
  end

  it "requires link targets" do
    item = build(:navigation_item, kind: "link", target_kind: "article", target_id: nil)

    expect(item).not_to be_valid
    expect(item.errors[:target_id]).to include("is required")
  end

  it "requires url for external links" do
    item = build(:navigation_item, kind: "link", target_kind: "external", url: "")

    expect(item).not_to be_valid
    expect(item.errors[:url]).to include("is required")
  end

  it "rejects parents from another navigation" do
    parent = create(:navigation_item)
    other_setting = Postnhost::Setting.create!
    item = build(:navigation_item, navigation: create(:navigation, setting: other_setting), parent:)

    expect(item).not_to be_valid
    expect(item.errors[:parent_id]).to include("must belong to same navigation")
  end

  it "allows only links inside dropdowns and columns" do
    navigation = create(:navigation)
    dropdown = create(:navigation_item, navigation:, kind: "dropdown", target_kind: nil, url: nil)
    column = create(:navigation_item, navigation:, container_kind: "footer", kind: "column", target_kind: nil, url: nil)

    dropdown_child = build(:navigation_item, navigation:, parent: dropdown, kind: "dropdown", target_kind: nil, url: nil)
    column_child = build(:navigation_item, navigation:, parent: column, kind: "column", target_kind: nil, url: nil)

    expect(dropdown_child).not_to be_valid
    expect(dropdown_child.errors[:kind]).to include("must be link inside dropdown")
    expect(column_child).not_to be_valid
    expect(column_child.errors[:kind]).to include("must be link inside column")
  end

  it "rejects children below links" do
    parent = create(:navigation_item)
    child = build(:navigation_item, navigation: parent.navigation, parent:)

    expect(child).not_to be_valid
    expect(child.errors[:parent_id]).to include("link items cannot have children")
  end

  it "requires grouping items to omit every target attribute" do
    item = build(
      :navigation_item,
      kind: "dropdown",
      target_kind: "external",
      target_id: 1,
      target_slug: "target",
      url: "https://example.com"
    )

    expect(item).not_to be_valid
    expect(item.errors[:target_kind]).to include("must be blank for grouping items")
    expect(item.errors[:target_id]).to include("must be blank for grouping items")
    expect(item.errors[:target_slug]).to include("must be blank for grouping items")
    expect(item.errors[:url]).to include("must be blank for grouping items")
  end

  it "requires link items to select a target kind" do
    item = build(:navigation_item, target_kind: nil, url: nil)

    expect(item).not_to be_valid
    expect(item.errors[:target_kind]).to include("is required for link items")
  end

  it "rejects target attributes on text links" do
    item = build(:navigation_item, target_kind: "text", target_id: 1, target_slug: "target", url: "https://example.com")

    expect(item).not_to be_valid
    expect(item.errors[:target_id]).to include("must be blank for text links")
    expect(item.errors[:target_slug]).to include("must be blank for text links")
    expect(item.errors[:url]).to include("must be blank for text links")
  end

  it "requires a slug for static page links" do
    item = build(:navigation_item, target_kind: "static_page", target_slug: nil, url: nil)

    expect(item).not_to be_valid
    expect(item.errors[:target_slug]).to include("is required")
  end
end

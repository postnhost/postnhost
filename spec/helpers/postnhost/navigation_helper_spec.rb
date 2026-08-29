require "rails_helper"

RSpec.describe Postnhost::NavigationHelper, type: :helper do
  let!(:default_language) { create(:language, :default) }
  let(:navigation) { create(:navigation) }

  before do
    helper.extend(Postnhost::CategoryHelper)
    helper.extend(Postnhost::PublicPagesHelper)
    helper.instance_variable_set(:@current_language, default_language)
  end

  it "resolves a shared target once for multiple navigation items" do
    article = create(:article, :published, language: default_language)
    first_item = create(:navigation_item, navigation:, target_kind: "article", target_id: article.id)
    second_item = create(:navigation_item, navigation:, target_kind: "article", target_id: article.id, position: 1)
    allow(Postnhost::Snapshot::Article).to receive(:where).and_call_original
    load_navigation_targets(first_item, second_item)

    expect(helper.navigation_href(first_item)).to eq("/#{article.slug}")
    expect(helper.navigation_href(first_item)).to eq("/#{article.slug}")
    expect(helper.navigation_href(second_item)).to eq("/#{article.slug}")
    expect(Postnhost::Snapshot::Article).to have_received(:where).once
  end

  it "caches missing targets and nil helper results" do
    item = create(
      :navigation_item,
      navigation:,
      target_kind: "article",
      target_id: 999_999,
      label_translations: {}
    )
    load_navigation_targets(item)

    expect(helper.navigation_href(item)).to be_nil
    expect(helper.navigation_href(item)).to be_nil
    expect(helper.navigation_label(item)).to be_nil
    expect(helper.navigation_label(item)).to be_nil
  end

  it "keeps target caches separate for different target kinds" do
    article = instance_double(Postnhost::Snapshot::Article, slug: "article-target", article_id: 42)
    page = instance_double(Postnhost::Snapshot::Page, slug: "page-target", page_id: 42)
    article_item = instance_double(Postnhost::NavigationItem, id: 1, kind: "link", target_kind: "article", target_id: 42)
    page_item = instance_double(Postnhost::NavigationItem, id: 2, kind: "link", target_kind: "page", target_id: 42)
    helper.instance_variable_set(:@navigation_target_cache, {
                                   "article" => { 42 => article },
                                   "page" => { 42 => page },
                                   "category" => {}
                                 })
    helper.instance_variable_set(:@navigation_variant_cache, {})

    expect(helper.navigation_href(article_item)).to eq("/#{article.slug}")
    expect(helper.navigation_href(page_item)).to eq("/#{page.slug}")
  end

  it "uses published localized variants for hrefs and fallback labels" do
    spanish_language = create(:language, :spanish)
    article = create(:article, :published, language: default_language, title: "English title")
    create(:article_variant, :published, article:, language: spanish_language, title: "Spanish title")
    first_item = create(:navigation_item, navigation:, target_kind: "article", target_id: article.id, label_translations: {})
    second_item = create(
      :navigation_item,
      navigation:,
      target_kind: "article",
      target_id: article.id,
      label_translations: {},
      position: 1
    )
    helper.instance_variable_set(:@current_language, spanish_language)
    load_navigation_targets(first_item, second_item)

    expect(helper.navigation_href(first_item)).to eq("/es/#{article.slug}")
    expect(helper.navigation_label(first_item)).to eq("Spanish title")
    expect(helper.navigation_href(second_item)).to eq("/es/#{article.slug}")
    expect(helper.navigation_label(second_item)).to eq("Spanish title")
  end

  it "falls back to default hrefs and labels for unpublished localized variants" do
    spanish_language = create(:language, :spanish)
    article = create(:article, :published, language: default_language, title: "English title")
    create(:article_variant, article:, language: spanish_language, title: "Draft Spanish title")
    item = create(:navigation_item, navigation:, target_kind: "article", target_id: article.id, label_translations: {})
    helper.instance_variable_set(:@current_language, spanish_language)
    load_navigation_targets(item)

    expect(helper.navigation_href(item)).to eq("/#{article.slug}")
    expect(helper.navigation_label(item)).to eq("English title")
  end

  it "omits unpublished targets and their draft labels" do
    article = create(:article, language: default_language, title: "Draft title")
    item = create(:navigation_item, navigation:, target_kind: "article", target_id: article.id, label_translations: {})
    load_navigation_targets(item)

    expect(helper.navigation_href(item)).to be_nil
    expect(helper.navigation_label(item)).to be_nil
  end

  it "derives fallback labels for every non-article target type" do
    page = create(:page, :published, language: default_language, title: "Published page")
    category = create(:category, name: "Published category")
    article = create(:article, :published, language: default_language)
    create(:article_category, article:, category:)
    Postnhost::Publishing::Articles::Publish.call(article:)

    page_item = create(:navigation_item, navigation:, target_kind: "page", target_id: page.id, label_translations: {})
    category_item = create(
      :navigation_item,
      navigation:,
      target_kind: "category",
      target_id: category.id,
      label_translations: {},
      position: 1
    )
    static_item = create(
      :navigation_item,
      navigation:,
      target_kind: "static_page",
      target_slug: "privacy-policy",
      url: nil,
      label_translations: {},
      position: 2
    )
    external_item = create(
      :navigation_item,
      navigation:,
      target_kind: "external",
      url: "https://example.com/docs",
      label_translations: {},
      position: 3
    )
    text_item = create(
      :navigation_item,
      navigation:,
      target_kind: "text",
      url: nil,
      label_translations: {},
      position: 4
    )
    load_navigation_targets(page_item, category_item, static_item, external_item, text_item)

    expect(helper.navigation_label(page_item)).to eq("Published page")
    expect(helper.navigation_label(category_item)).to eq("Published category")
    expect(helper.navigation_label(static_item)).to eq("Privacy policy")
    expect(helper.navigation_label(external_item)).to eq("https://example.com/docs")
    expect(helper.navigation_label(text_item)).to be_nil
  end

  it "builds external link security options with and without nofollow" do
    followed = build(:navigation_item, target_kind: "external", nofollow: false)
    nofollow = build(:navigation_item, target_kind: "external", nofollow: true)

    expect(helper.navigation_link_options(followed)).to eq(target: "_blank", rel: "noopener noreferrer")
    expect(helper.navigation_link_options(nofollow)).to eq(target: "_blank", rel: "noopener noreferrer nofollow")
  end

  def load_navigation_targets(*items)
    targets = Postnhost::PublicNavigationTargets.call(
      items:,
      language: helper.instance_variable_get(:@current_language)
    ).value
    helper.instance_variable_set(:@navigation_target_cache, targets.records)
    helper.instance_variable_set(:@navigation_variant_cache, targets.variants)
  end
end

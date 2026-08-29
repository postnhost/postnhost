require "rails_helper"

RSpec.describe "Navigation Settings", :js, type: :system do
  include FactoryBot::Syntax::Methods

  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before do
    Postnhost::Language.find_or_create_by!(html_lang: "en") do |lang|
      lang.name = "English"
      lang.default = true
    end

    Postnhost::Setting.current.update!(
      use_auto_header_navigation: false,
      use_auto_footer_navigation: false
    )

    sign_in_as(user)
  end

  it "keeps rendered tree visible while editing items" do
    visit postnhost.edit_settings_path(section: "navigation")
    wait_for_builder_ready

    clear_existing_items

    add_header_link
    footer_column_path = add_footer_column
    add_child(path: footer_column_path)

    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}.children.0']", wait: 3)

    trigger_click("button[data-path='header.0'][data-action='navigation-builder#toggleCollapse']")
    expect(page).to have_css("div[data-path='header.0'] > div.border-t.hidden", visible: :all)

    trigger_click("button[data-path='header.0'][data-action='navigation-builder#toggleCollapse']")
    expect(page).to have_no_css("div[data-path='header.0'] > div.border-t.hidden", visible: :all)
    expect(page).to have_css("div[data-path='header.0'] > div.border-t:not(.hidden)")

    set_label(path: "header.0", label: "Header Edited EN")
    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)

    configure_link_item(path: "header.0", label: "Header External EN", target_type: "External Link", target_value: "https://example.com/editing")
    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_css("input[data-path='header.0'][data-field='url']", visible: :all, wait: 3)

    set_label(path: footer_column_path, label: "Footer Column Edited EN")
    configure_link_item(
      path: "#{footer_column_path}.children.0",
      label: "Footer Link Edited EN",
      target_type: "External Link",
      target_value: "https://example.com/footer"
    )
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}.children.0']", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder']:not(.hidden)", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder']:not(.hidden)", wait: 3)

    click_button "Save Navigation"
    expect(page).to have_current_path(
      postnhost.edit_settings_path(section: "navigation", locale: "en"),
      wait: 5
    )
    wait_for_builder_ready
    # After reload, persisted items start collapsed (positive DB id). Only assert on the
    # outer cards (which are always visible). Deep children require explicit expand.
    expect(page).to have_css("div[data-path='header.0']", wait: 2)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 2)
    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder']:not(.hidden)", wait: 2)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder']:not(.hidden)", wait: 2)

    set_label(path: "header.0", label: "Header Edited Again EN")
    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)
  end

  it "keeps rendered tree visible when removing items before save" do
    visit postnhost.edit_settings_path(section: "navigation")
    wait_for_builder_ready

    clear_existing_items

    add_header_link
    dropdown_path = add_header_dropdown
    add_child(path: dropdown_path)
    footer_column_path = add_footer_column
    add_child(path: footer_column_path)

    trigger_click("button[data-path='#{dropdown_path}.children.0'][data-action='navigation-builder#removeItem']")
    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_css("div[data-path='#{dropdown_path}']", wait: 3)
    expect(page).to have_no_css("div[data-path='#{dropdown_path}.children.0']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder']:not(.hidden)", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder']:not(.hidden)", wait: 3)

    trigger_click("button[data-path='#{dropdown_path}'][data-action='navigation-builder#removeItem']")
    expect(page).to have_css("div[data-path='header.0']", wait: 3)
    expect(page).to have_no_css("div[data-path='header.1']", wait: 3)
    expect(page).to have_css("div[data-path='#{footer_column_path}']", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder']:not(.hidden)", wait: 3)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder']:not(.hidden)", wait: 3)
  end

  it "keeps submitted tree visible when save fails" do
    visit postnhost.edit_settings_path(section: "navigation")
    wait_for_builder_ready

    clear_existing_items

    add_header_link
    set_label(path: "header.0", label: "Invalid Header")

    click_button "Save Navigation"
    wait_for_builder_ready

    expect(page).to have_css("div[data-path='header.0']", wait: 2)
    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder']:not(.hidden)", wait: 2)
  end

  it "toggles automatic header and footer navigation independently" do
    visit postnhost.edit_settings_path(section: "navigation")
    wait_for_builder_ready

    find("input[data-navigation-builder-target='headerToggle']").click

    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder'].hidden", visible: :all)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder']:not(.hidden)")

    find("input[data-navigation-builder-target='footerToggle']").click

    expect(page).to have_css("div[data-navigation-builder-target='headerBuilder'].hidden", visible: :all)
    expect(page).to have_css("div[data-navigation-builder-target='footerBuilder'].hidden", visible: :all)

    find("input[data-navigation-builder-target='headerToggle']").click
    click_button "Save Navigation"
    expect(page).to have_current_path(
      postnhost.edit_settings_path(section: "navigation", locale: "en"),
      wait: 5
    )

    setting = Postnhost::Setting.current.reload
    expect(setting.use_auto_header_navigation).to be(false)
    expect(setting.use_auto_footer_navigation).to be(true)
  end

  private

  def set_label(path:, label:)
    ensure_expanded(path)
    field = find("input[data-path='#{path}'][data-field='label']", visible: :all)
    field.set(label)
  end

  def ensure_expanded(path)
    card = find("div[data-path='#{path}']", visible: :all)
    details = card.first(:css, ":scope > div.border-t", visible: :all)
    return unless details && details[:class].to_s.split.include?("hidden")

    trigger_click("button[data-path='#{path}'][data-action='navigation-builder#toggleCollapse']")
    expect(page).to have_no_css("div[data-path='#{path}'] > div.border-t.hidden", visible: :all, wait: 2)
  end

  def configure_link_item(path:, label:, target_type:, target_value: nil, nofollow: false)
    set_label(path:, label:)

    target_kind_value = target_kind_value_for(target_type)
    set_select_value(path:, field: "target_kind", value: target_kind_value)

    case target_type
    when "Text"
      nil
    when "External Link"
      url_input = find("input[data-path='#{path}'][data-field='url']", visible: :all)
      url_input.set(target_value)
      nofollow_checkbox = find("input[data-path='#{path}'][data-field='nofollow']", visible: :all)
      nofollow_checkbox.set(nofollow)
    when "Static Page"
      target_select = first("select[data-path='#{path}'][data-field='target_slug']", visible: :all, minimum: 0, wait: 5) ||
                      find("select[data-path='#{path}'][data-field='target_id']", visible: :all)
      value = target_value.presence || target_select.all("option", visible: :all).map(&:value).find(&:present?)
      set_select_value(path:, field: "target_slug", value: value)
    else
      target_select = find("select[data-path='#{path}'][data-field='target_id']", visible: :all)
      value = target_value.presence || target_select.all("option", visible: :all).map(&:value).find(&:present?)
      set_select_value(path:, field: "target_id", value: value)
    end
  end

  def set_select_value(path:, field:, value:)
    element = find("select[data-path='#{path}'][data-field='#{field}']", visible: :all)
    page.execute_script(<<~JS, element, value.to_s)
      arguments[0].value = arguments[1];
      arguments[0].dispatchEvent(new Event("change", { bubbles: true }));
    JS
  end

  def target_kind_value_for(target_type)
    {
      "Article" => "article",
      "Page" => "page",
      "Category" => "category",
      "Static Page" => "static_page",
      "External Link" => "external",
      "Text" => "text"
    }.fetch(target_type)
  end

  def clear_existing_items
    wait_for_builder_ready
    first("button[data-action='navigation-builder#removeItem']", visible: :all).click while page.has_css?("button[data-action='navigation-builder#removeItem']", wait: 0)
  end

  def add_header_link
    add_with_retry(
      trigger_selector: "button[data-action='navigation-builder#addHeaderLink']",
      expected_selector: "div[data-path='header.0']"
    )
    "header.0"
  end

  def add_header_dropdown
    add_with_retry(
      trigger_selector: "button[data-action='navigation-builder#addHeaderDropdown']",
      expected_selector: "div[data-path='header.0']"
    )
    "header.0"
  end

  def add_footer_column
    add_with_retry(
      trigger_selector: "button[data-action='navigation-builder#addFooterColumn']",
      expected_selector: "div[data-path='footer.0']"
    )
    "footer.0"
  end

  def add_child(path:)
    child_index = all("div[data-path^='#{path}.children.']", visible: :all).count
    add_with_retry(
      trigger_selector: "button[data-path='#{path}'][data-action='navigation-builder#addChild']",
      expected_selector: "div[data-path='#{path}.children.#{child_index}']"
    )
    "#{path}.children.#{child_index}"
  end

  def add_with_retry(trigger_selector:, expected_selector:)
    3.times do
      trigger_click(trigger_selector)
      return if page.has_css?(expected_selector, wait: 3)
    end

    expect(page).to have_css(expected_selector, wait: 3)
  end

  def trigger_click(selector)
    page.execute_script(<<~JS, selector)
      const element = document.querySelector(arguments[0]);
      if (!element) throw new Error(`Missing element for selector: ${arguments[0]}`);
      element.click();
    JS
  end

  def wait_for_builder_ready
    expect(page).to have_css("form[data-controller='navigation-builder']")
    expect(page).to have_css("form[data-controller='navigation-builder'][data-navigation-builder-ready='true']", wait: 5)
  end
end

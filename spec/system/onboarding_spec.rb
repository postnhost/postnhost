require "rails_helper"

RSpec.describe "Onboarding", type: :system do
  it "shows compact site details with search indexing enabled by default" do
    Postnhost::User.delete_all
    page.current_window.resize_to(1400, 900)

    visit postnhost.onboarding_path

    fill_in "Your name", with: "Admin User"
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "secret12"
    click_button "Continue"

    click_button "Continue"

    expect(page).to have_text("Set your site details")
    expect(page).to have_checked_field("site_indexing")
    expect(page.evaluate_script("document.documentElement.scrollHeight")).to be <= page.evaluate_script("window.innerHeight")

    uncheck "site_indexing"
    click_button "Continue"

    expect(page).to have_text("Start with sample content?")
    expect(page).to have_checked_field("generate_sample", with: "1")
    expect(page).to have_unchecked_field("generate_sample", with: "0")
    expect(Postnhost::Setting.current.reload.site_indexing).to eq("noindex")
  end
end

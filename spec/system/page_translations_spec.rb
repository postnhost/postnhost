require "rails_helper"

RSpec.describe "Page translations", type: :system do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before { sign_in_as(user) }

  it "creates a manual translation, publishes it, and serves it on the localized URL" do
    page_record = create(:page, :published, user:, language: default_language,
                                            title: "Pricing", slug: "pricing",
                                            content: "<p>Pricing details</p>")

    visit postnhost.page_variants_path(page_record)

    expect(page).to have_text("Page Translations")
    expect(page).to have_button("Translate with AI")

    click_button "Manual Translation"
    click_button "Manual Translation" unless page.has_link?("Spanish", wait: 2)
    click_link "Spanish"

    expect(page).to have_current_path(%r{/pages/#{page_record.id}/variants/\d+/edit}, url: true)

    variant = page_record.page_variants.find_by!(language: spanish)
    expect(variant.title).to eq("Pricing")

    click_button "Actions" if page.has_no_link?("Publish Now", wait: 1)
    click_link "Publish Now"

    expect(page).to have_link("Unpublish")
    expect(variant.reload).to be_published

    visit postnhost.localized_public_static_page_path(locale: "es", slug: "pricing")

    expect(page).to have_text("Pricing details")
  end

  it "lists generating AI translations as in progress" do
    page_record = create(:page, :published, user:, language: default_language, title: "About", slug: "about")
    page_record.page_variants.create!(language: spanish, generating: true)

    visit postnhost.page_variants_path(page_record)

    expect(page).to have_text("Untitled Translation")
    expect(page).to have_css("input[type=checkbox][disabled]")
  end
end

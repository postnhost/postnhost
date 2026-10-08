require "rails_helper"

RSpec.describe "API and MCP access", type: :system do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  before { sign_in_as(user) }

  it "creates a token, hides its secret on return and revokes it" do
    visit postnhost.api_tokens_path
    page.execute_script(
      "arguments[0].value = arguments[1]; arguments[0].form.requestSubmit(arguments[2])",
      find_field("Name", readonly: false), "Writing agent", find_button("Create token")
    )
    expect(page).to have_text("Writing agent")
    expect(page).to have_css("code", text: /pnh_\w+/)

    find_link("Articles").execute_script("this.click()")
    expect(page).to have_current_path(postnhost.articles_path)
    find_link("API & MCP").execute_script("this.click()")
    expect(page).to have_no_css("code", text: /pnh_\w+/)
    find_button("Revoke").execute_script("this.click()")
    expect(page).to have_text("Revoked")
    expect(page).to have_no_button("Revoke")
  end
end

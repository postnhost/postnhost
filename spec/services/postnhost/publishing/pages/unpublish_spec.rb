require "rails_helper"

RSpec.describe Postnhost::Publishing::Pages::Unpublish, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "removes a page snapshot" do
    page = create(:page, :published, language: default_language)

    result = described_class.call(page:)

    expect(result).to be_success
    expect(page.reload.page_snapshot).to be_nil
  end
end

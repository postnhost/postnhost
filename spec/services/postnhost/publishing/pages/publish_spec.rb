require "rails_helper"

RSpec.describe Postnhost::Publishing::Pages::Publish, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "publishes a page" do
    page = create(:page, language: default_language)

    result = described_class.call(page:)

    expect(result).to be_success
    expect(result.value).to be_a(Postnhost::Snapshot::Page)
    expect(page.reload.page_snapshot).to eq(result.value)
  end
end

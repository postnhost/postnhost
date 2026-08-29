require "rails_helper"

RSpec.describe Postnhost::Publishing::PageVariants::PublishMany, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "publishes selected variants" do
    page = create(:page, :published, language: default_language)
    spanish = create(:page_variant, page:, language: create(:language, :spanish))
    german = create(:page_variant, page:, language: create(:language, :german))

    result = described_class.call(page:, ids: [spanish.id, german.id])

    expect(result).to be_success
    expect(result.value[:successes]).to contain_exactly(spanish, german)
    expect(page.page_variants.joins(:page_variant_snapshot).count).to eq(2)
  end
end

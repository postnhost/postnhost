require "rails_helper"

RSpec.describe Postnhost::Publishing::PageVariants::Publish, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "publishes a page variant" do
    page = create(:page, :published, language: default_language)
    variant = create(:page_variant, page:, language: spanish)

    result = described_class.call(page_variant: variant)

    expect(result).to be_success
    expect(result.value).to be_a(Postnhost::Snapshot::PageVariant)
    expect(variant.reload.page_variant_snapshot).to eq(result.value)
  end
end

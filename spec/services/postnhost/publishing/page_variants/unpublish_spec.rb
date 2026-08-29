require "rails_helper"

RSpec.describe Postnhost::Publishing::PageVariants::Unpublish, type: :service do
  let!(:default_language) { create(:language, :default) }
  let!(:spanish) { create(:language, :spanish) }

  it "removes a page variant snapshot" do
    page = create(:page, :published, language: default_language)
    variant = create(:page_variant, :published, page:, language: spanish)

    result = described_class.call(page_variant: variant)

    expect(result).to be_success
    expect(variant.reload.page_variant_snapshot).to be_nil
  end
end

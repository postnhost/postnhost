require "rails_helper"

RSpec.describe Postnhost::PagyHelper, type: :helper do
  describe "#pagination_url" do
    it "keeps first pages canonical and preserves unrelated query parameters" do
      pagy = build_pagy(page: 2, params: { "page" => "2", "utm_source" => "newsletter" })

      expect(helper.pagination_url(pagy, 1)).to eq("/?utm_source=newsletter")
      expect(helper.pagination_url(pagy, 2)).to eq("/?page=2&utm_source=newsletter")
    end

    it "removes only the current pagination key" do
      pagy = build_pagy(
        page: 2,
        page_key: "articles_page",
        params: { "articles_page" => "2", "article_variants_page" => "3" }
      )

      expect(helper.pagination_url(pagy, 1)).to eq("/?article_variants_page=3")
    end
  end

  describe "#pagination_series" do
    it "returns all pages when they fit in the configured slots" do
      pagy = build_pagy(count: 45, page: 2, slots: 3)

      expect(helper.pagination_series(pagy)).to eq([1, 2, 3])
    end

    it "returns a sliding window for compact pagination" do
      pagy = build_pagy(count: 150, page: 5, slots: 3)

      expect(helper.pagination_series(pagy)).to eq([4, 5, 6])
    end

    it "includes boundary pages and gaps for the default navigation" do
      pagy = build_pagy(count: 300, page: 10)

      expect(helper.pagination_series(pagy)).to eq([1, :gap, 9, 10, 11, :gap, 20])
    end
  end

  def build_pagy(count: 100, page: 1, slots: nil, page_key: "page", params: {})
    request = Data.define(:base_url, :path, :params).new(
      base_url: "http://www.example.com",
      path: "/",
      params:
    )
    options = { count:, page:, limit: 15, page_key:, request: }
    options[:slots] = slots if slots

    Pagy::Offset.new(**options)
  end
end

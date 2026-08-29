require "rails_helper"

RSpec.describe Postnhost::Configuration do
  subject(:configuration) { described_class.new }

  it "defaults public pagination to twelve without inventing a site URL" do
    expect(configuration.site_url).to be_nil
    expect(configuration.public_page_size).to eq(12)
  end

  it "normalizes a configured site URL" do
    configuration.site_url = " https://blog.example.com/ "

    expect(configuration.site_url).to eq("https://blog.example.com")
  end

  it "allows the configured site URL to remain blank" do
    configuration.site_url = " "

    expect(configuration.site_url).to be_nil
  end

  it "rejects a configured site URL with a path" do
    expect { configuration.site_url = "https://example.com/blog" }
      .to raise_error(ArgumentError, "site_url must be an HTTP(S) origin without a path, query, or fragment")
  end

  it "accepts an integer-like configured page size" do
    configuration.public_page_size = "24"

    expect(configuration.public_page_size).to eq(24)
  end

  it "rejects a configured page size outside the supported range" do
    expect { configuration.public_page_size = 101 }
      .to raise_error(ArgumentError, "public_page_size must be an integer between 1 and 100")
  end
end

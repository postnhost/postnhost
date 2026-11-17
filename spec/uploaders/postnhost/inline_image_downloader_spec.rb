require "rails_helper"

RSpec.describe Postnhost::InlineImageDownloader do
  subject(:downloader) { described_class.new(Postnhost::InlineArticleImageUploader.new) }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with("example.com").and_return(["1.1.1.1"])
  end

  it "downloads a public image with its original metadata" do
    stub_request(:get, "https://example.com/photo.png").to_return(body: "image", headers: { "Content-Type" => "image/png" })

    file = downloader.download("https://example.com/photo.png")

    expect(file.read).to eq("image")
    expect(file.content_type).to eq("image/png")
    expect(file.original_filename).to eq("photo.png")
  end

  it "rejects oversized downloads while reading the response" do
    stub_request(:get, "https://example.com/large.png").to_return(body: "x" * (20.megabytes + 1))

    expect { downloader.download("https://example.com/large.png") }.to raise_error(CarrierWave::DownloadError, "File too large")
  end

  it "rejects private network addresses" do
    expect { downloader.download("http://127.0.0.1/image.png") }.to raise_error(CarrierWave::DownloadError)
  end

  it "rejects redirects to private network addresses" do
    stub_request(:get, "https://example.com/redirect").to_return(status: 302, headers: { "Location" => "http://169.254.169.254/image.png" })

    expect { downloader.download("https://example.com/redirect") }.to raise_error(CarrierWave::DownloadError)
  end

  it "rejects non-HTTP sources" do
    expect { downloader.download("file:///etc/passwd") }.to raise_error(CarrierWave::DownloadError)
  end

  it "rejects HTTP errors" do
    stub_request(:get, "https://example.com/missing.png").to_return(status: 404)

    expect { downloader.download("https://example.com/missing.png") }.to raise_error(CarrierWave::DownloadError)
  end
end

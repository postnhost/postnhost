require "rails_helper"

RSpec.describe Postnhost::InlineImageUploadable, type: :model do
  let!(:default_language) { create(:language, :default) }
  let(:article) { create(:article, language: default_language) }
  let(:file) { instance_double(ActionDispatch::Http::UploadedFile, content_type: "image/png", size: 1.megabyte) }
  let(:uploader) do
    instance_double(
      Postnhost::InlineArticleImageUploader,
      store!: true,
      url: "https://example.com/inline.webp",
      identifier: "inline.webp"
    )
  end

  before do
    allow(Postnhost::InlineArticleImageUploader).to receive(:new).with(article, :inline_image).and_return(uploader)
  end

  it "stores supported images and returns their public attributes" do
    expect(article.upload_inline_image(file)).to eq(
      success: true,
      url: "https://example.com/inline.webp",
      filename: "inline.webp"
    )
  end

  it "rejects unsupported content types before storage" do
    allow(file).to receive(:content_type).and_return("text/plain")

    expect(article.upload_inline_image(file)).to eq(success: false, error: "Invalid file type")
    expect(uploader).not_to have_received(:store!)
  end

  it "rejects oversized images before storage" do
    allow(file).to receive(:size).and_return(21.megabytes)

    expect(article.upload_inline_image(file)).to eq(success: false, error: "File too large")
    expect(uploader).not_to have_received(:store!)
  end

  it "normalizes CarrierWave processing failures" do
    allow(Rails.logger).to receive(:error)
    allow(uploader).to receive(:store!).and_raise(CarrierWave::ProcessingError, "broken image")

    expect(article.upload_inline_image(file)).to eq(success: false, error: "Invalid image file")
    expect(Rails.logger).to have_received(:error).with("CarrierWave inline image error: broken image")
  end

  it "normalizes unexpected storage failures" do
    allow(Rails.logger).to receive(:error)
    allow(uploader).to receive(:store!).and_raise(StandardError, "storage unavailable")

    expect(article.upload_inline_image(file)).to eq(success: false, error: "Error processing image")
    expect(Rails.logger).to have_received(:error).with("Inline image processing error: storage unavailable")
  end

  it "requires including classes to choose an uploader" do
    uploadable_class = Class.new do
      include Postnhost::InlineImageUploadable
    end

    expect do
      uploadable_class.new.send(:inline_image_uploader_class)
    end.to raise_error(NotImplementedError, "including class must define #inline_image_uploader_class")
  end
end

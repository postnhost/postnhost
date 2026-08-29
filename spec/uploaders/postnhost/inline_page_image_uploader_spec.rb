require "rails_helper"

RSpec.describe Postnhost::InlinePageImageUploader do
  around do |example|
    with_isolated_uploader_root { example.run }
  end

  describe "#store!" do
    it "stores a generated webp inline image under the page directory" do
      page = create(:page)
      uploader = described_class.new(page, :inline_image)

      allow(SecureRandom).to receive(:hex).with(12).and_return("b" * 24)

      uploader.store!(uploaded_image(postnhost_asset_image_path("demo.webp"), "image/webp"))

      expect(uploader.store_dir).to eq("uploads/pages/#{page.user_id}/#{page.id}/inline_images")
      expect(uploader.identifier).to eq("#{'b' * 24}.webp")
      expect(File).to exist(uploader.file.path)
      expect(image_dimensions(uploader.file.path).first).to eq(1200)
    end
  end

  describe "#extension_allowlist" do
    it "allows supported image extensions" do
      expect(described_class.new.extension_allowlist).to eq(%w[png jpg jpeg gif webp heic])
    end
  end

  describe "#size_range" do
    it "allows files up to 20 megabytes" do
      expect(described_class.new.size_range).to cover(20.megabytes)
      expect(described_class.new.size_range).not_to cover(20.megabytes + 1)
    end
  end
end

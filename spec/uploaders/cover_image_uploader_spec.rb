require "rails_helper"

RSpec.describe CoverImageUploader do
  around do |example|
    with_isolated_uploader_root { example.run }
  end

  describe "#store!" do
    it "stores a webp cover image with medium and thumbnail versions" do
      stored_at = Time.zone.local(2026, 1, 1, 12, 0, 0)
      article = create(:article)
      uploader = described_class.new(article, :cover_image)

      travel_to stored_at do
        uploader.store!(uploaded_image(dummy_public_image_path("icon.png"), "image/png"))
      end

      expect(uploader.store_dir).to eq(hashed_store_dir(article, :cover_image))
      expect(uploader.identifier).to eq(hashed_webp_filename(article, :cover_image, stored_at))
      expect(File).to exist(uploader.file.path)
      expect(image_dimensions(uploader.file.path)).to eq([1200, 630])
      expect(image_dimensions(uploader.medium.file.path)).to eq([1024, 537])
      expect(image_dimensions(uploader.thumbnail.file.path)).to eq([780, 410])
    end
  end

  describe "#extension_allowlist" do
    it "allows supported image extensions" do
      expect(described_class.new.extension_allowlist).to eq(%w[png jpg jpeg gif webp heic])
    end
  end
end

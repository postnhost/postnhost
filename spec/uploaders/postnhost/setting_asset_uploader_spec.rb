require "rails_helper"

RSpec.describe Postnhost::SettingAssetUploader do
  around do |example|
    with_isolated_uploader_root { example.run }
  end

  describe "#store!" do
    it "stores a webp asset in the hashed setting directory without resizing it" do
      stored_at = Time.zone.local(2026, 1, 1, 12, 0, 0)
      setting = Postnhost::Setting.current
      uploader = described_class.new(setting, :site_logo)

      travel_to stored_at do
        uploader.store!(uploaded_image(dummy_public_image_path("icon.png"), "image/png"))
      end

      expect(uploader.store_dir).to eq(hashed_store_dir(setting, :site_logo))
      expect(uploader.identifier).to eq(hashed_webp_filename(setting, :site_logo, stored_at))
      expect(File).to exist(uploader.file.path)
      expect(image_dimensions(uploader.file.path)).to eq([512, 512])
    end
  end

  describe "#extension_allowlist" do
    it "allows supported image extensions" do
      expect(described_class.new.extension_allowlist).to eq(%w[png jpg jpeg gif webp heic])
    end
  end
end

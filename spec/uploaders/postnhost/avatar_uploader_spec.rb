require "rails_helper"

RSpec.describe Postnhost::AvatarUploader do
  around do |example|
    with_isolated_uploader_root { example.run }
  end

  describe "#store!" do
    it "stores a 200 by 200 webp avatar in the hashed user directory" do
      stored_at = Time.zone.local(2026, 1, 1, 12, 0, 0)
      user = create(:user)
      uploader = described_class.new(user, :avatar_file)

      travel_to stored_at do
        uploader.store!(uploaded_image(dummy_public_image_path("icon.png"), "image/png"))
      end

      expect(uploader.store_dir).to eq(hashed_store_dir(user, :avatar_file))
      expect(uploader.identifier).to eq(hashed_webp_filename(user, :avatar_file, stored_at))
      expect(File).to exist(uploader.file.path)
      expect(image_dimensions(uploader.file.path)).to eq([200, 200])
    end
  end

  describe "#extension_allowlist" do
    it "allows supported image extensions" do
      expect(described_class.new.extension_allowlist).to eq(%w[png jpg jpeg gif webp heic])
    end
  end

  describe "#size_range" do
    it "allows files up to 25 megabytes" do
      expect(described_class.new.size_range).to cover(25.megabytes)
      expect(described_class.new.size_range).not_to cover(25.megabytes + 1)
    end
  end
end

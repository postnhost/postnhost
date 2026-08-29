require "rails_helper"

RSpec.describe BaseUploader do
  around do |example|
    with_isolated_uploader_root { example.run }
  end

  describe "#store_dir" do
    it "uses a hashed model and mounted attribute directory" do
      article = create(:article)
      uploader = described_class.new(article, :cover_image)

      expect(uploader.store_dir).to eq(hashed_store_dir(article, :cover_image))
    end
  end

  describe "#size_range" do
    it "allows files up to 25 megabytes" do
      uploader = described_class.new(create(:article), :cover_image)

      expect(uploader.size_range).to cover(25.megabytes)
      expect(uploader.size_range).not_to cover(25.megabytes + 1)
    end
  end
end

require "rails_helper"

RSpec.describe Postnhost::SampleData do
  describe ".seed_author_profile!" do
    it "fills blank author profile fields for sample content" do
      user = create(
        :user,
        position: nil,
        bio: nil,
        website_url: nil,
        x_url: nil,
        linkedin_url: nil,
        youtube_url: nil,
        bluesky_url: nil
      )

      described_class.seed_author_profile!(user)

      user.reload
      expect(user.position).to eq("Editor")
      expect(user.bio).to include("Demo author for PostnHost")
      expect(user.website_url).to eq("https://example.com/demo-author")
      expect(user.x_url).to eq("https://x.com/postnhostdemo")
      expect(user.linkedin_url).to eq("https://linkedin.com/in/postnhost-demo")
      expect(user.youtube_url).to eq("https://youtube.com/@postnhostdemo")
      expect(user.bluesky_url).to eq("https://bsky.app/profile/postnhost-demo.example.com")
    end

    it "does not overwrite existing author profile fields" do
      user = create(
        :user,
        position: "Founder",
        bio: "Existing bio",
        website_url: "https://example.com/existing"
      )

      described_class.seed_author_profile!(user)

      user.reload
      expect(user.position).to eq("Founder")
      expect(user.bio).to eq("Existing bio")
      expect(user.website_url).to eq("https://example.com/existing")
    end
  end
end

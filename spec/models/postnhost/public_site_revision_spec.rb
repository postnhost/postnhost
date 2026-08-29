require "rails_helper"

RSpec.describe Postnhost::PublicSiteRevision, type: :model do
  describe ".current" do
    it "creates the singleton when it does not exist" do
      expect { described_class.current }.to change(described_class, :count).by(1)

      expect(described_class.current.id).to eq(described_class::SINGLETON_ID)
      expect(described_class.current.revision).to eq(0)
    end

    it "returns the existing singleton" do
      revision = described_class.current

      expect { described_class.current }.not_to change(described_class, :count)
      expect(described_class.current).to eq(revision)
    end
  end

  describe ".locked" do
    it "creates and returns the singleton" do
      expect(described_class.locked).to eq(described_class.current)
    end
  end

  describe ".bump!" do
    it "creates and increments the singleton" do
      expect { described_class.bump! }
        .to change { described_class.current.revision }
        .from(0).to(1)
    end
  end
end

require "rails_helper"

RSpec.describe Postnhost::Template, type: :model do
  describe "validations" do
    it "allows known template names" do
      described_class::NAMES.each do |name|
        expect(described_class.new(name:)).to be_valid
      end
    end

    it "rejects unknown template names" do
      template = described_class.new(name: "unknown")

      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("is not included in the list")
    end
  end

  describe ".current" do
    it "creates default singleton record when missing" do
      described_class.delete_all

      template = described_class.current

      expect(template.name).to eq("default")
      expect(described_class.count).to eq(1)
    end
  end

  describe ".active_name" do
    it "returns persisted template name" do
      template = described_class.current
      template.update!(name: "workspace-journal")

      expect(described_class.active_name).to eq("workspace-journal")
    end
  end
end

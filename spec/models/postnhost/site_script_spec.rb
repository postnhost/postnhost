require "rails_helper"

RSpec.describe Postnhost::SiteScript, type: :model do
  let!(:setting) { Postnhost::Setting.current }

  it "accepts complete tags without validating their markup" do
    site_script = described_class.new(
      setting:,
      placement: "head",
      script: '<vendor-verification data-key="abc"></vendor-verification>'
    )

    expect(site_script).to be_valid
  end

  it "allows the script field to be blank" do
    site_script = described_class.new(setting:, placement: "head", script: "")

    expect(site_script).to be_valid
  end

  it "rejects unknown placement values" do
    site_script = described_class.new(setting:, placement: "footer", script: "<script></script>")

    expect(site_script).not_to be_valid
    expect(site_script.errors[:placement]).to include("is not included in the list")
  end

  it "invalidates public caches when a tag is created, updated, or destroyed" do
    revision = Postnhost::PublicSiteRevision.current
    site_script = nil

    expect do
      site_script = described_class.create!(setting:, placement: "head", script: '<meta name="first">')
    end.to change { revision.reload.revision }.by(1)

    expect do
      site_script.update!(script: '<meta name="second">')
    end.to change { revision.reload.revision }.by(1)

    expect do
      site_script.destroy!
    end.to change { revision.reload.revision }.by(1)
  end
end

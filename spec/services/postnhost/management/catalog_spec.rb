require "rails_helper"

RSpec.describe Postnhost::Management::Catalog do
  it "reuses the same immutable schema on repeated lookups" do
    tool = described_class.fetch("articles_create")
    expect(described_class.fetch("articles_create")).to equal(tool)
    expect { tool[:inputSchema][:properties]["attributes"][:properties]["title"][:type] << "integer" }.to raise_error(FrozenError)
    expect { tool[:name].replace("other") }.to raise_error(FrozenError)
  end
end

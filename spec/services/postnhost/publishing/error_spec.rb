require "rails_helper"

RSpec.describe Postnhost::Publishing::Error, type: :service do
  it "normalizes messages and exposes a readable exception message" do
    error = described_class.new(%w[first second])

    expect(error.messages).to eq(%w[first second])
    expect(error.message).to eq("first, second")
  end
end

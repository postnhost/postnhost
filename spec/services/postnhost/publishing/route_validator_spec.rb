require "rails_helper"

RSpec.describe Postnhost::Publishing::RouteValidator, type: :service do
  let!(:default_language) { create(:language, :default) }

  it "accepts an unused slug" do
    expect { described_class.validate!(slug: "unused-slug") }.not_to raise_error
  end

  it "rejects a slug used by an article snapshot" do
    create(:article, :published, language: default_language, slug: "used-slug")

    expect { described_class.validate!(slug: "used-slug") }
      .to raise_error(Postnhost::Publishing::Error, "slug has already been published by an article")
  end
end

require "rails_helper"

RSpec.describe "PaperTrail isolation", type: :model do
  let!(:default_language) { create(:language, :default) }

  it "stores host and engine versions independently" do
    host_post = HostPost.create!(title: "Host draft")
    host_post.update!(title: "Host published")

    article = create(:article, language: default_language)
    engine_version = article.paper_trail.save_with_version

    expect(host_post.versions).to all(be_a(PaperTrail::Version))
    expect(host_post.versions).to all(have_attributes(item_type: "HostPost"))
    expect(engine_version).to be_a(Postnhost::Version)
    expect(article.versions).to contain_exactly(engine_version)
    expect(PaperTrail::Version.where(item_type: "Postnhost::Article")).to be_empty
    expect(Postnhost::Version.where(item_type: "HostPost")).to be_empty
  end
end

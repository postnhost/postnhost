require "rails_helper"

RSpec.describe "Public pagination settings", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  around do |example|
    original_public_page_size = Postnhost.config.public_page_size
    example.run
  ensure
    Postnhost.configure { |config| config.public_page_size = original_public_page_size }
  end

  it "uses the configured public page size" do
    Postnhost::Setting.current.update!(public_page_size: 2)
    articles = create_list(:article, 3, :published, language: default_language, user:)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(articles.second.title, articles.third.title)
    expect(response.body).not_to include(articles.first.title)
  end

  it "uses the initializer default when the dashboard value is blank" do
    Postnhost::Setting.current.update!(public_page_size: nil)
    Postnhost.configure { |config| config.public_page_size = 2 }
    articles = create_list(:article, 3, :published, language: default_language, user:)

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(articles.second.title, articles.third.title)
    expect(response.body).not_to include(articles.first.title)
  end
end

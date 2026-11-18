require "rails_helper"

RSpec.describe "Public social image alt text", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:user) { create(:user) }

  before { host! "example.com" }

  it "uses the English default for both social image tags" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css('meta[property="og:image:alt"]')["content"]).to eq("postnhost - Modern blogging platform")
    expect(response.parsed_body.at_css('meta[name="twitter:image:alt"]')["content"]).to eq("postnhost - Modern blogging platform")
  end

  it "uses the site's custom translation for both tags and escapes it safely" do
    Postnhost::Setting.current.update!(locale_overrides: {
                                         "en" => { "postnhost.public.site.og_image_alt" => 'Our "blog" <image>' }
                                       })

    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css('meta[property="og:image:alt"]')["content"]).to eq('Our "blog" <image>')
    expect(response.parsed_body.at_css('meta[name="twitter:image:alt"]')["content"]).to eq('Our "blog" <image>')
    expect(response.body).to include("Our &quot;blog&quot; &lt;image&gt;")
  end

  it "uses the requested language's translation" do
    create(:language, :german)

    get "/de"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css('meta[property="og:image:alt"]')["content"]).to eq("postnhost – Moderne Blogging-Plattform")
    expect(response.parsed_body.at_css('meta[name="twitter:image:alt"]')["content"]).to eq("postnhost – Moderne Blogging-Plattform")
  end

  it "preserves an article's own cover image alt text" do
    article = create(:article, :published, language: default_language, user: user,
                                           cover_image: fixture_file_upload("cover_image.webp", "image/webp"),
                                           cover_image_alt: "A creator planning their next video")
    Postnhost::Setting.current.update!(locale_overrides: {
                                         "en" => { "postnhost.public.site.og_image_alt" => "Site image description" }
                                       })

    get "/#{article.slug}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css('meta[property="og:image:alt"]')["content"]).to eq("A creator planning their next video")
    expect(response.parsed_body.at_css('meta[name="twitter:image:alt"]')["content"]).to eq("A creator planning their next video")
  end
end

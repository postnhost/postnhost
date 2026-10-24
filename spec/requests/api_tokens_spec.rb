require "rails_helper"

RSpec.describe "CMS API token management", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  before do
    host! "example.com"
    sign_in user
  end

  it "stores a usable token without persisting its secret" do
    post postnhost.api_tokens_path, params: { api_token: { name: "Agent" } }
    expect(response).to have_http_status(:ok)
    secret = response.body[/pnh_[A-Za-z0-9_-]+/]
    token = user.api_tokens.last
    expect(token.attributes.values).not_to include(secret)
    expect(Postnhost::ApiToken.authenticate(secret)).to eq(token)
  end

  it "prevents revoking another user's token" do
    other_token, = Postnhost::ApiToken.issue!(user: create(:user), name: "Other")
    delete postnhost.api_token_path(other_token)
    expect(response).to have_http_status(:not_found)
    expect(other_token.reload.revoked_at).to be_nil
  end
end

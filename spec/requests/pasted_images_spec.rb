require "rails_helper"

RSpec.describe "Pasted image uploads", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:image_data) { File.binread(Postnhost::Engine.root.join("spec/fixtures/files/cover_image.webp")) }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with("example.com").and_return(["1.1.1.1"])
  end

  around do |example|
    with_isolated_uploader_root { example.run }
  end

  %i[article page].each do |resource_type|
    context "with a #{resource_type}" do
      let(:record) { create(resource_type, user:) }
      let(:upload_path) { postnhost.public_send("#{resource_type}_images_path", record) }

      it "requires authentication for remote imports" do
        post upload_path, params: { url: "https://example.com/photo.webp" }

        expect(response).to redirect_to(postnhost.new_session_path)
      end

      it "stores the imported image through the inline uploader" do
        sign_in(user)
        stub_request(:get, "https://example.com/photo.webp").to_return(body: image_data, headers: { "Content-Type" => "image/webp" })

        post upload_path, params: { url: "https://example.com/photo.webp" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.fetch("url")).to match(%r{/uploads/#{resource_type}s/#{user.id}/#{record.id}/inline_images/[a-f0-9]{24}\.webp\z})
        expect(response.parsed_body.fetch("url")).not_to include("example.com")
      end

      it "rejects non-image responses" do
        sign_in(user)
        stub_request(:get, "https://example.com/photo.webp").to_return(body: "not an image", headers: { "Content-Type" => "text/html" })

        post upload_path, params: { url: "https://example.com/photo.webp" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("error" => "Invalid file type")
      end

      it "rejects internal network sources" do
        sign_in(user)

        post upload_path, params: { url: "http://127.0.0.1/private.png" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).not_to have_key("url")
      end
    end
  end
end

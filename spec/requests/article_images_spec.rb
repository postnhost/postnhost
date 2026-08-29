require "rails_helper"

RSpec.describe "Article images", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user:) }
  let(:file) do
    tempfile = Tempfile.new(["article-upload", ".png"])
    tempfile.binmode
    tempfile.write("fake-image-content")
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(
      tempfile:,
      filename: "article-upload.png",
      type: "image/png"
    )
  end

  after { file.tempfile.close! }

  describe "POST /articles/:article_id/images" do
    it "requires authentication" do
      post postnhost.article_images_path(article)

      expect(response).to redirect_to(postnhost.new_session_path)
    end

    it "returns bad request when the file is missing" do
      sign_in(user)

      post postnhost.article_images_path(article)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("error" => "No file provided")
    end

    it "returns the uploaded image URL" do
      sign_in(user)
      allow(Postnhost::Article).to receive(:find).with(article.id.to_s).and_return(article)
      allow(article).to receive(:upload_inline_image).and_return(
        success: true,
        url: "https://example.com/article.webp",
        filename: "article.webp"
      )

      post postnhost.article_images_path(article), params: { file: file }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("url" => "https://example.com/article.webp")
    end

    it "returns an upload error" do
      sign_in(user)
      allow(Postnhost::Article).to receive(:find).with(article.id.to_s).and_return(article)
      allow(article).to receive(:upload_inline_image).and_return(success: false, error: "Invalid file type")

      post postnhost.article_images_path(article), params: { file: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "Invalid file type")
    end
  end

  describe "POST /articles/:article_id/cover_image" do
    before do
      sign_in(user)
      allow(Postnhost::Article).to receive(:find).with(article.id.to_s).and_return(article)
    end

    it "returns bad request when the file is missing" do
      post postnhost.article_cover_image_path(article)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to eq("error" => "No file provided")
    end

    it "returns the stored cover image URL" do
      allow(article).to receive(:cover_image=)
      allow(article).to receive(:save).and_return(true)
      allow(article.cover_image).to receive(:url).and_return("https://example.com/cover.webp")

      post postnhost.article_cover_image_path(article), params: { file: file }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("url" => "https://example.com/cover.webp")
    end

    it "returns validation errors" do
      allow(article).to receive(:cover_image=)
      allow(article).to receive(:save).and_return(false)
      article.errors.add(:cover_image, "is invalid")

      post postnhost.article_cover_image_path(article), params: { file: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "Cover image is invalid")
    end
  end

  describe "DELETE /articles/:article_id/cover_image" do
    it "clears the stored identifier" do
      article.update_column(:cover_image, "existing.webp")
      sign_in(user)

      delete postnhost.article_cover_image_path(article)

      expect(response).to have_http_status(:no_content)
      expect(article.reload.read_attribute(:cover_image)).to be_nil
    end
  end
end

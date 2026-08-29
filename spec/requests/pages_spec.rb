require "rails_helper"

RSpec.describe "Pages", type: :request do
  let!(:default_language) { create(:language, :default) }
  let!(:user) { create(:user) }
  let(:image_page) { create(:page, user:) }

  describe "GET /pages" do
    it "redirects guests to sign in" do
      get postnhost.pages_path

      expect(response).to redirect_to(postnhost.new_session_path)
    end

    it "shows dynamic pages and code-defined templates for authenticated users" do
      create(:page, :published, user:, title: "About", slug: "about")
      sign_in(user)

      get postnhost.pages_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Pages")
      expect(response.body).to include("About")
      expect(response.body).to include("Code-defined static pages")
      expect(response.body).to include("Terms")
      expect(response.body).to include("/terms")
      expect(response.body).to include("Code-defined")
      expect(response.body).to include("not editable in the admin panel")
    end

    it "shows an untouched draft without generating a public path" do
      sign_in(user)
      get postnhost.new_page_path

      draft_page = Postnhost::Page.last
      expect(draft_page.slug).to be_nil

      get postnhost.pages_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Untitled Page")
      expect(response.body).not_to include("Not set")
      expect(response.parsed_body.css("code").map(&:text)).not_to include("/")
    end
  end

  describe "GET /pages/new" do
    before { sign_in(user) }

    it "creates a draft page and redirects to edit" do
      expect do
        get postnhost.new_page_path
      end.to change(Postnhost::Page, :count).by(1)

      created_page = Postnhost::Page.last
      expect(response).to redirect_to(postnhost.edit_page_path(created_page))
      expect(created_page.user).to eq(user)
    end
  end

  describe "GET /pages/:id/edit" do
    before { sign_in(user) }

    it "returns not found when the page does not exist" do
      get postnhost.edit_page_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /pages/:id/publish" do
    before { sign_in(user) }

    it "publishes a page" do
      page = create(:page, user:)

      patch postnhost.publish_page_path(page)

      expect(response).to redirect_to(postnhost.edit_page_path(page))
      expect(page.reload.published?).to be(true)
    end
  end

  describe "PATCH /pages/:id/unpublish" do
    before { sign_in(user) }

    it "unpublishes a page" do
      page = create(:page, :published, user:)

      patch postnhost.unpublish_page_path(page)

      expect(response).to redirect_to(postnhost.edit_page_path(page))
      expect(page.reload.published?).to be(false)
    end
  end

  describe "PATCH /pages/:id" do
    before { sign_in(user) }

    it "supports autosave json requests without redirecting to edit" do
      page = create(:page, user:, title: "Old Title")

      patch postnhost.page_path(page),
            params: { page: { title: "New Title" } },
            headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:no_content)
      expect(page.reload.title).to eq("New Title")
    end

    it "returns validation errors for HTML, JSON, and Turbo Stream requests" do
      page = create(:page, user:, title: "Valid page")
      invalid_params = { page: { title: "Changed", slug: "INVALID SLUG" } }

      patch postnhost.page_path(page), params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Slug can only contain lowercase letters, numbers, and hyphens")

      patch postnhost.page_path(page), params: invalid_params, headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include("Slug can only contain lowercase letters, numbers, and hyphens")

      patch postnhost.page_path(page), params: invalid_params, headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to be_empty
    end
  end

  describe "DELETE /pages/:id" do
    it "destroys the page" do
      page = create(:page, user:)
      sign_in(user)

      expect do
        delete postnhost.page_path(page)
      end.to change(Postnhost::Page, :count).by(-1)

      expect(response).to redirect_to(postnhost.pages_path)
    end
  end

  describe "POST /pages/:page_id/images" do
    it "redirects guests to sign in" do
      post postnhost.page_images_path(image_page)

      expect(response).to redirect_to(postnhost.new_session_path)
    end

    it "returns bad request when file is missing" do
      sign_in(user)

      post postnhost.page_images_path(image_page)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include("error" => "No file provided")
    end

    it "returns uploaded image URL on success" do
      sign_in(user)

      allow(Postnhost::Page).to receive(:find).with(image_page.id.to_s).and_return(image_page)
      allow(image_page).to receive(:upload_inline_image).and_return(
        { success: true, url: "https://example.com/uploads/page.webp", filename: "page.webp" }
      )

      tempfile = Tempfile.new(["page-upload", ".png"])
      tempfile.binmode
      tempfile.write("fake-image-content")
      tempfile.rewind
      file = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: "page-upload.png",
        type: "image/png"
      )
      post postnhost.page_images_path(image_page), params: { file: file }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("url" => "https://example.com/uploads/page.webp")
    ensure
      tempfile.close!
    end

    it "returns the uploader error" do
      sign_in(user)
      allow(Postnhost::Page).to receive(:find).with(image_page.id.to_s).and_return(image_page)
      allow(image_page).to receive(:upload_inline_image).and_return(success: false, error: "File too large")
      tempfile = Tempfile.new(["page-upload", ".png"])
      tempfile.write("fake-image-content")
      tempfile.rewind
      file = ActionDispatch::Http::UploadedFile.new(
        tempfile:,
        filename: "page-upload.png",
        type: "image/png"
      )

      post postnhost.page_images_path(image_page), params: { file: file }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("error" => "File too large")
    ensure
      tempfile&.close!
    end
  end
end

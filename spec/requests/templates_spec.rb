require "rails_helper"

RSpec.describe "Template", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  before do
    sign_in user
    Postnhost::Template.current
  end

  describe "GET /template/edit" do
    it "returns success and shows design page with previews" do
      get postnhost.edit_template_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Template")
      expect(response.body).to include("Workspace Journal")
      expect(response.body).to include("iframe")
      expect(response.body).to include("data-controller=\"template-preview\"")
      expect(response.body).to include("data-action=\"template-preview#update\"")
      expect(response.body).to include("The preview updates before saving.")
    end
  end

  describe "PATCH /template" do
    it "stores template selection only" do
      patch postnhost.template_path, params: {
        template: {
          name: "workspace-journal"
        }
      }

      expect(response).to redirect_to(postnhost.edit_template_path)
      expect(flash[:notice]).to eq("Template settings were successfully updated.")

      expect(Postnhost::Template.current.reload.name).to eq("workspace-journal")
    end
  end
end

require "rails_helper"

RSpec.describe Postnhost::LanguageSwitcher, type: :controller do
  concern_module = described_class

  controller(ApplicationController) do
    include concern_module

    def index
      render plain: "ok"
    end
  end

  around do |example|
    I18n.with_locale(I18n.locale) { example.run }
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  describe "#set_language_data" do
    it "creates English default when no languages exist" do
      expect { get :index }.to change(Postnhost::Language, :count).by(1)

      current_language = controller.instance_variable_get(:@current_language)
      expect(current_language.html_lang).to eq("en")
      expect(current_language.default).to be(true)
      expect(I18n.locale).to eq(:en)
    end

    it "uses existing default language without creating English" do
      default_language = create(:language, :spanish, default: true)

      expect { get :index }.not_to change(Postnhost::Language, :count)

      expect(controller.instance_variable_get(:@current_language)).to eq(default_language)
      expect(I18n.locale).to eq(:es)
    end

    it "uses requested locale when present" do
      create(:language, :spanish, default: true)
      requested_language = create(:language, :russian)

      get :index, params: { locale: requested_language.html_lang }

      expect(controller.instance_variable_get(:@current_language)).to eq(requested_language)
      expect(I18n.locale).to eq(:ru)
    end

    it "falls back to default when requested locale does not exist" do
      default_language = create(:language, :german, default: true)

      get :index, params: { locale: "xx" }

      expect(controller.instance_variable_get(:@current_language)).to eq(default_language)
      expect(I18n.locale).to eq(:de)
    end
  end
end

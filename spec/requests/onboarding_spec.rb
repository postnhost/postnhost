require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  describe "GET /onboarding" do
    it "redirects to sign in when users already exist" do
      create(:user)

      get postnhost.onboarding_path

      expect(response).to redirect_to(postnhost.new_session_path)
    end

    it "shows step 1 when no users exist" do
      Postnhost::User.delete_all

      get postnhost.onboarding_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your name")
    end

    it "resets an expired setup session" do
      Postnhost::User.delete_all
      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Expired Admin",
          email: "expired@example.com",
          password: "secret12"
        }
      }
      Postnhost::User.delete_all

      get postnhost.onboarding_path

      expect(response).to redirect_to(postnhost.onboarding_path)
      expect(flash[:alert]).to eq("Setup session expired. Start again.")
    end
  end

  describe "full setup flow" do
    before { Postnhost::User.delete_all }

    it "accepts step 1 payload under user scope" do
      patch postnhost.onboarding_path, params: {
        step: "1",
        user: {
          name: "Admin User",
          email: "admin-user-scope@example.com",
          password: "secret12"
        }
      }

      expect(response).to redirect_to(postnhost.onboarding_path)
      expect(Postnhost::User.find_by(email: "admin-user-scope@example.com")).to be_present
    end

    it "shows i18n fallback warning for non-english locale" do
      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "fallback@example.com",
          password: "secret12"
        }
      }
      patch postnhost.onboarding_path, params: {
        step: "2",
        language_locales: %w[fr en],
        default_locale: "fr"
      }

      follow_redirect!

      expect(response.body).to include("config.i18n.fallbacks = [:en]")
    end

    it "prefills the site URL from the onboarding request origin" do
      Postnhost::Setting.current.update!(site_url: nil)
      host! "www.example.com"
      https!

      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "origin@example.com",
          password: "secret12"
        }
      }
      patch postnhost.onboarding_path, params: {
        step: "2",
        language_locales: %w[en],
        default_locale: "en"
      }

      follow_redirect!

      expect(response.body).to include("Site URL")
      expect(response.body).to include('value="https://www.example.com"')
    end

    it "creates admin, settings, optional sample data, and signs in" do
      get postnhost.onboarding_path
      expect(response).to have_http_status(:ok)

      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "admin@example.com",
          password: "secret12"
        }
      }
      expect(response).to redirect_to(postnhost.onboarding_path)
      follow_redirect!
      expect(response.body).to include("Choose blog languages")

      patch postnhost.onboarding_path, params: {
        step: "2",
        language_locales: %w[en fr],
        default_locale: "en"
      }
      expect(response).to redirect_to(postnhost.onboarding_path)
      follow_redirect!
      expect(response.body).to include("Site Name")
      expect(response.body).to include("Tagline")
      expect(response.body).to include("Subtitle")
      expect(response.body).to include("Meta Title")
      expect(response.body).to include("Meta Description")
      expect(response.body).to include("Allow search engines to index this site")
      expect(response.body).to include('type="checkbox"')
      expect(response.body).not_to include(">postnhost.public.site.schema_site_name</label>")

      patch postnhost.onboarding_path, params: {
        step: "3",
        site_url: "https://blog.example.com",
        site_indexing: "noindex",
        translations: {
          "postnhost.public.site.schema_site_name" => "My Site",
          "postnhost.public.site.blog_tagline" => "Tag",
          "postnhost.public.site.blog_subtitle" => "Sub",
          "postnhost.public.site.blog_meta_description" => "Meta desc",
          "postnhost.public.site.blog_meta_title" => "Meta title"
        }
      }
      expect(response).to redirect_to(postnhost.onboarding_path)
      follow_redirect!
      expect(response.body).to include("Start with sample content?")

      categories_before = Postnhost::Category.count
      articles_before = Postnhost::Article.count

      patch postnhost.onboarding_path, params: { step: "4", generate_sample: "1" }

      expect(Postnhost::Category.count).to be > categories_before
      expect(Postnhost::Article.count).to be > articles_before
      expect(response).to redirect_to(postnhost.onboarding_path(post_install: "1"))

      follow_redirect!
      expect(response.body).to include("Production checklist")
      expect(response.body).to include("Go to Dashboard")
      expect(response.body).to include("robots.txt")
      expect(response.body).to include("S3 upload settings")

      patch postnhost.onboarding_path, params: { step: "post_install_done" }
      expect(response).to redirect_to(postnhost.articles_path)

      welcome_article = Postnhost::Article.find_by(title: "Welcome to PostnHost")
      expect(welcome_article).to be_present
      expect(welcome_article.cover_image?).to be(true)
      expect(Postnhost::Language.count).to eq(2)
      expect(Postnhost::Language.blog_default&.html_lang).to eq("en")
      expect(Postnhost::Language.exists?(html_lang: "fr")).to be(true)

      get postnhost.articles_path
      expect(response).to have_http_status(:ok)

      setting = Postnhost::Setting.current.reload
      en = setting.locale_overrides.fetch("en", {})
      expect(en["postnhost.public.site.schema_site_name"]).to eq("My Site")
      expect(setting.site_url).to eq("https://blog.example.com")
      expect(setting.site_indexing).to eq("noindex")
    end

    it "skips sample data when declined" do
      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "skip@example.com",
          password: "secret12"
        }
      }
      patch postnhost.onboarding_path, params: {
        step: "2",
        language_locales: %w[en],
        default_locale: "en"
      }
      patch postnhost.onboarding_path, params: {
        step: "3",
        site_indexing: "index",
        translations: {
          "postnhost.public.site.schema_site_name" => "X",
          "postnhost.public.site.blog_tagline" => "X",
          "postnhost.public.site.blog_subtitle" => "X",
          "postnhost.public.site.blog_meta_description" => "X",
          "postnhost.public.site.blog_meta_title" => "X"
        }
      }

      categories_before = Postnhost::Category.count

      patch postnhost.onboarding_path, params: { step: "4", generate_sample: "0" }

      expect(response).to redirect_to(postnhost.onboarding_path(post_install: "1"))
      expect(Postnhost::Category.count).to eq(categories_before)
    end

    it "rejects step 2 when default locale is not selected" do
      patch postnhost.onboarding_path, params: {
        step: "1",
        postnhost_user: {
          name: "Admin User",
          email: "invalid-default@example.com",
          password: "secret12"
        }
      }

      patch postnhost.onboarding_path, params: {
        step: "2",
        language_locales: %w[en],
        default_locale: "fr"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Default language must be one of the selected languages.")
    end

    it "redirects invalid steps with an explanation" do
      patch postnhost.onboarding_path, params: { step: "unknown" }

      expect(response).to redirect_to(postnhost.onboarding_path)
      expect(flash[:alert]).to eq("Invalid step.")
    end
  end
end

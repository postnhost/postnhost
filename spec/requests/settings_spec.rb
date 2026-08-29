require "rails_helper"

RSpec.describe "Settings", type: :request do
  let!(:default_language) { create(:language, :default) }
  let(:user) { create(:user) }

  before do
    sign_in user
    Postnhost::Setting.current
  end

  describe "GET /settings/edit?section=site" do
    it "returns success and shows site settings" do
      get postnhost.edit_settings_path(section: "site")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Site URL")
      expect(response.body).to include("Allow search engines to index this site")
      expect(response.body).to include('type="checkbox"')
      expect(response.body).to include("Articles per page")
      expect(response.body).to include("Save Site Settings")
    end
  end

  describe "PATCH /settings?section=site" do
    it "stores the canonical site URL, search visibility, and public page size" do
      patch postnhost.settings_path(section: "site"), params: {
        setting: {
          site_url: "https://blog.example.com/",
          site_indexing: "noindex",
          public_page_size: "24"
        }
      }

      setting = Postnhost::Setting.current.reload

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "site"))
      expect(flash[:notice]).to eq("Settings were successfully updated.")
      expect(setting.site_url).to eq("https://blog.example.com")
      expect(setting.site_indexing).to eq("noindex")
      expect(setting.public_page_size).to eq(24)
    end

    it "renders validation errors for an invalid site origin" do
      patch postnhost.settings_path(section: "site"), params: {
        setting: {
          site_url: "https://blog.example.com/articles",
          public_page_size: "15"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Site url must be an HTTP(S) origin without a path, query, or fragment")
    end

    it "allows site defaults to remain blank for initializer fallback" do
      patch postnhost.settings_path(section: "site"), params: {
        setting: {
          site_url: "",
          public_page_size: ""
        }
      }

      setting = Postnhost::Setting.current.reload
      expect(response).to redirect_to(postnhost.edit_settings_path(section: "site"))
      expect(setting.site_url).to be_nil
      expect(setting.public_page_size).to be_nil
      expect(setting.effective_public_page_size).to eq(12)
    end
  end

  describe "GET /settings/edit?section=scripts" do
    it "returns success and shows the scripts section" do
      setting = Postnhost::Setting.current
      setting.site_scripts.create!(
        placement: "head",
        script: '<script src="https://analytics.ahrefs.com/analytics.js" async></script>'
      )

      get postnhost.edit_settings_path(section: "scripts")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Scripts")
      expect(response.body).to include("Add script")
      expect(response.body).to include("analytics.ahrefs.com/analytics.js")
    end

    it "escapes stored tags in the CMS editor" do
      payload = '</textarea><script data-cms-xss>window.alert("cms")</script>'
      Postnhost::Setting.current.site_scripts.create!(placement: "head", script: payload)

      get postnhost.edit_settings_path(section: "scripts")

      document = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(document.css("script[data-cms-xss]")).to be_empty
      expect(document.css("textarea").map(&:text)).to include(payload)
    end
  end

  describe "POST /settings/site_scripts" do
    it "creates a valid script record" do
      expect do
        post postnhost.settings_site_scripts_path(section: "scripts"), params: {
          site_script: {
            placement: "head",
            script: '<meta name="robots" content="noindex">'
          }
        }
      end.to change(Postnhost::SiteScript, :count).by(1)

      setting = Postnhost::Setting.current
      script = setting.site_scripts.order(:id).last

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "scripts"))
      expect(script.placement).to eq("head")
      expect(script.script).to eq('<meta name="robots" content="noindex">')
    end

    it "accepts arbitrary complete tag markup" do
      post postnhost.settings_site_scripts_path(section: "scripts"), params: {
        site_script: {
          placement: "head",
          script: '<vendor-check key="unrestricted"></vendor-check>'
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "scripts"))
      expect(Postnhost::SiteScript.order(:id).last.script).to eq('<vendor-check key="unrestricted"></vendor-check>')
    end

    it "requires an authenticated CMS user" do
      delete postnhost.session_path

      expect do
        post postnhost.settings_site_scripts_path(section: "scripts"), params: {
          site_script: {
            placement: "head",
            script: "<script>alert('unsafe')</script>"
          }
        }
      end.not_to change(Postnhost::SiteScript, :count)

      expect(response).to redirect_to(postnhost.new_session_path)
    end
  end

  describe "PATCH /settings/site_scripts/:id" do
    it "updates existing script settings" do
      setting = Postnhost::Setting.current
      script = setting.site_scripts.create!(
        placement: "head",
        script: '<script src="https://cdn.example.com/first.js"></script>'
      )

      patch postnhost.settings_site_script_path(script, section: "scripts"), params: {
        site_script: {
          placement: "body_end",
          script: '<script src="https://cdn.example.com/second.js" defer></script>'
        }
      }

      script.reload

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "scripts"))
      expect(script.placement).to eq("body_end")
      expect(script.script).to eq('<script src="https://cdn.example.com/second.js" defer></script>')
    end

    it "shows validation errors in the product layout and preserves submitted values" do
      setting = Postnhost::Setting.current
      script = setting.site_scripts.create!(
        placement: "head",
        script: '<script src="https://cdn.example.com/first.js"></script>'
      )

      patch postnhost.settings_site_script_path(script, section: "scripts"), params: {
        site_script: {
          placement: "footer",
          script: '<script src="https://cdn.example.com/second.js"></script>'
        }
      }

      document = response.parsed_body
      edit_form = document.at_css("form[action*='/settings/site_scripts/#{script.id}']")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Placement is not included in the list")
      expect(document.at_css("body")["class"].split).to include("h-screen")
      expect(document.at_css("#menu")).to be_present
      expect(edit_form.at_css("textarea").text).to eq('<script src="https://cdn.example.com/second.js"></script>')
      expect(script.reload.placement).to eq("head")
    end
  end

  describe "DELETE /settings/site_scripts/:id" do
    it "destroys an existing script record" do
      setting = Postnhost::Setting.current
      script = setting.site_scripts.create!(
        placement: "body_end",
        script: '<script src="https://cdn.example.com/remove.js"></script>'
      )

      expect do
        delete postnhost.settings_site_script_path(script, section: "scripts")
      end.to change(Postnhost::SiteScript, :count).by(-1)

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "scripts"))
    end
  end

  describe "GET /settings/edit?section=i18n" do
    let!(:german_language) { create(:language, :german) }

    it "returns success and keeps en first in locale selector" do
      get postnhost.edit_settings_path(section: "i18n")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="en"')
      expect(response.body).to include('value="de"')
      expect(response.body.index('value="en"')).to be < response.body.index('value="de"')
    end

    it "shows human-readable site labels with their locale keys" do
      get postnhost.edit_settings_path(section: "i18n")

      expect(response.body).to include("Site Name (postnhost.public.site.schema_site_name)")
      expect(response.body).to include("Tagline (postnhost.public.site.blog_tagline)")
      expect(response.body).to include("Subtitle (postnhost.public.site.blog_subtitle)")
      expect(response.body).to include("Meta Title (postnhost.public.site.blog_meta_title)")
      expect(response.body).to include("Meta Description (postnhost.public.site.blog_meta_description)")
    end
  end

  describe "GET /settings/edit?section=timezone" do
    it "returns success and shows timezone settings" do
      get postnhost.edit_settings_path(section: "timezone")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Timezone")
      expect(response.body).to include("Default timezone from config")
    end
  end

  describe "PATCH /settings?section=timezone" do
    it "stores timezone value" do
      patch postnhost.settings_path(section: "timezone"), params: {
        setting: {
          timezone: "Europe/Berlin"
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "timezone"))
      expect(flash[:notice]).to eq("Settings were successfully updated.")
      expect(Postnhost::Setting.current.reload.timezone).to eq("Europe/Berlin")
    end
  end

  describe "GET /settings/edit?section=feature_flags" do
    it "returns success and shows feature flags settings" do
      get postnhost.edit_settings_path(section: "feature_flags")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Feature Flags")
      expect(response.body).to include("Author pages")
      expect(response.body).to include("Site search")
      expect(response.body).to include("Show “Powered by PostnHost”")
      expect(response.body).to include("Save Feature Flags")
    end
  end

  describe "PATCH /settings?section=feature_flags" do
    it "stores author pages toggle" do
      patch postnhost.settings_path(section: "feature_flags"), params: {
        setting: {
          author_pages_enabled: "0"
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "feature_flags"))
      expect(flash[:notice]).to eq("Settings were successfully updated.")
      expect(Postnhost::Setting.current.reload.author_pages_enabled).to be(false)
    end

    it "stores site search toggle" do
      patch postnhost.settings_path(section: "feature_flags"), params: {
        setting: {
          search_enabled: "0"
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "feature_flags"))
      expect(flash[:notice]).to eq("Settings were successfully updated.")
      expect(Postnhost::Setting.current.reload.search_enabled).to be(false)
    end

    it "stores powered by toggle" do
      patch postnhost.settings_path(section: "feature_flags"), params: {
        setting: {
          show_powered_by: "0"
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "feature_flags"))
      expect(flash[:notice]).to eq("Settings were successfully updated.")
      expect(Postnhost::Setting.current.reload.show_powered_by).to be(false)
    end
  end

  describe "PATCH /settings?section=i18n" do
    it "stores locale overrides for edited keys" do
      patch postnhost.settings_path(section: "i18n"), params: {
        locale_key: "en",
        translations: {
          "postnhost.public.site.schema_site_name" => "postnhost custom"
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "i18n", locale: "en"))
      expect(Postnhost::Setting.current.locale_overrides.dig("en", "postnhost.public.site.schema_site_name")).to eq("postnhost custom")
    end

    it "removes overrides when value matches base locale file" do
      base_site_name = Postnhost::Settings::I18nOverrides
                       .base_flat_translations("en")
                       .fetch("postnhost.public.site.schema_site_name")
      Postnhost::Setting.current.update!(locale_overrides: { "en" => { "postnhost.public.site.schema_site_name" => "postnhost custom" } })

      patch postnhost.settings_path(section: "i18n"), params: {
        locale_key: "en",
        translations: {
          "postnhost.public.site.schema_site_name" => base_site_name
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "i18n", locale: "en"))
      expect(Postnhost::Setting.current.locale_overrides).to eq({})
    end

    it "removes overrides when value is blank" do
      Postnhost::Setting.current.update!(locale_overrides: { "en" => { "postnhost.public.site.schema_site_name" => "postnhost custom" } })

      patch postnhost.settings_path(section: "i18n"), params: {
        locale_key: "en",
        translations: {
          "postnhost.public.site.schema_site_name" => ""
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "i18n", locale: "en"))
      expect(Postnhost::Setting.current.locale_overrides).to eq({})
    end

    it "explains that a language is required before editing translations" do
      Postnhost::Language.delete_all

      patch postnhost.settings_path(section: "i18n"), params: {
        translations: {
          "postnhost.public.site.schema_site_name" => "Custom site"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Create at least one language before editing i18n settings.")
      expect(Postnhost::Setting.current.locale_overrides).to eq({})
    end
  end

  describe "GET /settings/edit?section=schema" do
    it "returns success and shows schema settings" do
      get postnhost.edit_settings_path(section: "schema")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Schema")
      expect(response.body).to include("Article Defaults")
    end
  end

  describe "PATCH /settings?section=schema" do
    let!(:german_language) { create(:language, :german) }

    it "stores schema settings and locale overrides" do
      patch postnhost.settings_path(section: "schema"), params: {
        locale_key: "de",
        schema_settings: {
          organization_type: "Organization",
          default_article_type: "Report",
          contact_email: "editor@example.com",
          same_as: "https://example.com/a\nhttps://example.com/b",
          policies: {
            corrections_policy: "https://example.com/corrections"
          }
        },
        schema_translations: {
          website_name: "Postnhost DE",
          website_description: "German website description",
          organization_name: "Postnhost Redaktion",
          organization_alternate_name: "PH DE",
          organization_description: "German organization description"
        }
      }

      setting = Postnhost::Setting.current.reload
      expect(response).to redirect_to(postnhost.edit_settings_path(section: "schema", locale: "de"))
      expect(setting.schema_settings["organization_type"]).to eq("Organization")
      expect(setting.schema_settings["default_article_type"]).to eq("Report")
      expect(setting.schema_settings["same_as"]).to eq(["https://example.com/a", "https://example.com/b"])
      expect(setting.schema_settings.dig("policies", "corrections_policy")).to eq("https://example.com/corrections")
      expect(setting.schema_locale_overrides.dig("de", "website_name")).to eq("Postnhost DE")
    end

    it "removes non-default locale overrides when values match default locale" do
      setting = Postnhost::Setting.current
      setting.update!(
        schema_locale_overrides: {
          "en" => { "website_name" => "Default Site Name" },
          "de" => { "website_name" => "Default Site Name" }
        }
      )

      patch postnhost.settings_path(section: "schema"), params: {
        locale_key: "de",
        schema_settings: {},
        schema_translations: {
          website_name: "Default Site Name",
          website_description: "",
          organization_name: "",
          organization_alternate_name: "",
          organization_description: ""
        }
      }

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "schema", locale: "de"))
      expect(setting.reload.schema_locale_overrides).to eq({ "en" => { "website_name" => "Default Site Name" } })
    end
  end

  describe "GET /settings/edit?section=navigation" do
    it "returns success and shows navigation settings" do
      get postnhost.edit_settings_path(section: "navigation")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Navigation")
      expect(response.body).to include("Use auto-generated header navigation")
      expect(response.body).to include("Use auto-generated footer navigation")
    end
  end

  describe "PATCH /settings?section=navigation" do
    let!(:article) { create(:article, :published) }

    it "stores toggle and navigation tree" do
      patch postnhost.settings_path(section: "navigation"), params: {
        locale_key: "en",
        setting: {
          use_auto_header_navigation: "0",
          use_auto_footer_navigation: "1"
        },
        navigation: {
          tree: {
            header: [
              { id: -1, kind: "link", label: "Docs", target_kind: "external", url: "https://example.com", nofollow: true, children: [] }
            ],
            footer: []
          }.to_json
        }
      }

      setting = Postnhost::Setting.current.reload
      item = setting.current_navigation.navigation_items.first

      expect(response).to redirect_to(postnhost.edit_settings_path(section: "navigation", locale: "en"))
      expect(setting.use_auto_header_navigation).to be(false)
      expect(setting.use_auto_footer_navigation).to be(true)
      expect(item.label_translations["en"]).to eq("Docs")
      expect(item.target_kind).to eq("external")
      expect(item.nofollow).to be(true)
    end

    it "rejects a navigation tree whose containers are not arrays" do
      patch postnhost.settings_path(section: "navigation"), params: {
        locale_key: "en",
        setting: {
          use_auto_header_navigation: "0",
          use_auto_footer_navigation: "0"
        },
        navigation: {
          tree: { header: "invalid", footer: [] }.to_json
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Navigation payload is invalid")
      expect(Postnhost::Setting.current.current_navigation.navigation_items).to be_empty
    end

    it "rejects a navigation tree whose root is not an object" do
      patch postnhost.settings_path(section: "navigation"), params: {
        locale_key: "en",
        setting: {
          use_auto_header_navigation: "0",
          use_auto_footer_navigation: "0"
        },
        navigation: {
          tree: [].to_json
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Navigation payload is invalid")
      expect(Postnhost::Setting.current.current_navigation.navigation_items).to be_empty
    end
  end
end

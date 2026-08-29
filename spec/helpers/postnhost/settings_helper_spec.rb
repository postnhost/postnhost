require "rails_helper"

RSpec.describe Postnhost::SettingsHelper, type: :helper do
  describe "#render_site_scripts" do
    it "renders complete tags without escaping or modifying them" do
      setting = Postnhost::Setting.current
      allow(helper).to receive(:setting_current).and_return(setting)

      setting.site_scripts.create!(
        placement: "head",
        script: '<script src="https://example.com/analytics.js" data-key="abc" async></script>'
      )
      setting.site_scripts.create!(
        placement: "head",
        script: '<meta name="vendor-verification" content="token">'
      )

      output = helper.render_site_scripts("head")

      expect(output).to include('<script src="https://example.com/analytics.js" data-key="abc" async></script>')
      expect(output).to include('<meta name="vendor-verification" content="token">')
      expect(output).not_to include("&lt;script")
    end

    it "renders only tags assigned to the requested placement" do
      setting = Postnhost::Setting.current
      allow(helper).to receive(:setting_current).and_return(setting)

      setting.site_scripts.create!(placement: "head", script: '<script src="/head.js"></script>')
      setting.site_scripts.create!(placement: "body_end", script: '<script src="/body.js"></script>')

      output = helper.render_site_scripts("body_end")

      expect(output).to include('src="/body.js"')
      expect(output).not_to include('src="/head.js"')
    end
  end

  describe "#site_copy_label" do
    it "returns a human-readable site label" do
      expect(helper.site_copy_label("postnhost.public.site.blog_meta_title")).to eq("Meta Title")
    end

    it "includes the locale key when requested" do
      expect(
        helper.site_copy_label("postnhost.public.site.blog_meta_title", include_key: true)
      ).to eq("Meta Title (postnhost.public.site.blog_meta_title)")
    end
  end

  describe "#setting_site_logo_src" do
    it "returns the uploaded site logo when present" do
      setting = instance_double(
        Postnhost::Setting,
        site_logo?: true,
        site_logo: double(url: "https://cdn.example.com/site-logo.webp")
      )

      allow(helper).to receive(:setting_current).and_return(setting)

      expect(helper.setting_site_logo_src).to eq("https://cdn.example.com/site-logo.webp")
    end

    it "falls back to the engine default logo asset" do
      setting = instance_double(Postnhost::Setting, site_logo?: false)

      allow(helper).to receive(:setting_current).and_return(setting)

      expect(helper.setting_site_logo_src).to eq("postnhost/logo.webp")
    end
  end

  describe "#setting_og_image_src" do
    it "returns the uploaded og image when present" do
      setting = instance_double(
        Postnhost::Setting,
        og_image?: true,
        og_image: double(url: "https://cdn.example.com/default-og.webp")
      )

      allow(helper).to receive(:setting_current).and_return(setting)

      expect(helper.setting_og_image_src).to eq("https://cdn.example.com/default-og.webp")
    end

    it "falls back to the engine default og image asset" do
      setting = instance_double(Postnhost::Setting, og_image?: false)

      allow(helper).to receive(:setting_current).and_return(setting)

      expect(helper.setting_og_image_src).to eq("postnhost/og-image.webp")
    end
  end

  describe "#setting_site_logo_absolute_url" do
    it "uses the engine asset url when no uploaded logo exists" do
      setting = instance_double(Postnhost::Setting, site_logo?: false)

      allow(helper).to receive(:setting_current).and_return(setting)
      allow(helper).to receive(:asset_url).with("postnhost/logo.webp").and_return("http://test.host/assets/postnhost/logo.webp")

      expect(helper.setting_site_logo_absolute_url).to eq("http://test.host/assets/postnhost/logo.webp")
    end
  end

  describe "#setting_og_image_absolute_url" do
    it "uses the engine asset url when no uploaded og image exists" do
      setting = instance_double(Postnhost::Setting, og_image?: false)

      allow(helper).to receive(:setting_current).and_return(setting)
      allow(helper).to receive(:asset_url).with("postnhost/og-image.webp").and_return("http://test.host/assets/postnhost/og-image.webp")

      expect(helper.setting_og_image_absolute_url).to eq("http://test.host/assets/postnhost/og-image.webp")
    end
  end
end

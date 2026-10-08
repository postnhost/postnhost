module Postnhost
  module Management
    module Resources
      TEXT = %w[title title_tag og_title meta_description content language_id].freeze
      EXCERPT = %w[custom_excerpt use_excerpt_as_meta_description].freeze
      ARTICLE = (TEXT + EXCERPT + %w[schema_headline schema_article_type slug cover_image_alt scheduled_at top_pick author_ids category_ids suggested_article_ids]).freeze
      PAGE = (TEXT + %w[slug]).freeze
      USER = %w[email name slug position bio website_url x_url linkedin_url threads_url tiktok_url youtube_url facebook_url instagram_url bluesky_url mastodon_url password password_confirmation].freeze
      SETTING = %w[site_url site_indexing public_page_size timezone author_pages_enabled search_enabled show_powered_by use_auto_header_navigation use_auto_footer_navigation schema_settings schema_locale_overrides].freeze
      DEFINITIONS = {
        "api_tokens" => { model: "ApiToken", fields: %w[name] },
        "articles" => { model: "Article", fields: ARTICLE, snapshot: :article_snapshot },
        "pages" => { model: "Page", fields: PAGE, snapshot: :page_snapshot },
        "categories" => { model: "Category", fields: %w[name slug meta_description] },
        "languages" => { model: "Language", fields: %w[name html_lang default] },
        "users" => { model: "User", fields: USER + %w[schema_profile schema_locale_overrides] },
        "article_variants" => { model: "ArticleVariant", fields: TEXT + EXCERPT + %w[schema_headline], parent: "articles", snapshot: :article_variant_snapshot },
        "page_variants" => { model: "PageVariant", fields: TEXT, parent: "pages", snapshot: :page_variant_snapshot },
        "category_variants" => { model: "CategoryVariant", fields: %w[name meta_description language_id], parent: "categories" },
        "settings" => { model: "Setting", fields: SETTING, singleton: true },
        "template" => { model: "Template", fields: %w[name], singleton: true },
        "site_scripts" => { model: "SiteScript", fields: %w[placement script] }
      }.freeze

      def self.model(resource)
        Postnhost.const_get(DEFINITIONS.fetch(resource).fetch(:model), false)
      end
    end
  end
end

module Postnhost
  module SeoHelper
    include Postnhost::ApplicationHelper
    include Postnhost::SettingsHelper
    include Postnhost::SchemaHelper

    SCHEMA_CONTEXT = "https://schema.org".freeze
    DEFAULT_LANGUAGE = "en".freeze

    def site_description
      schema_website_description
    end

    def schema_site_name
      schema_website_name
    end

    def page_title
      fallback_title = I18n.t("postnhost.public.site.blog_meta_title")
      candidate = content_for?(:title) ? content_for(:title) : fallback_title
      normalize_meta_text(candidate).presence || fallback_title
    end

    def page_description
      return nil if omit_description_for_paginated_public_index?

      candidate = content_for?(:meta_description) ? content_for(:meta_description) : site_description
      normalize_meta_text(candidate).presence || site_description
    end

    def og_title
      candidate = content_for?(:og_title) ? content_for(:og_title) : page_title
      normalize_meta_text(candidate).presence || page_title
    end

    def schema_headline
      candidate = content_for?(:schema_headline) ? content_for(:schema_headline) : page_title
      normalize_meta_text(candidate).presence || page_title
    end

    def meta_description_content
      page_description
    end

    def render_description_meta_tags?
      meta_description_content.present?
    end

    def page_url
      @page_url ||= begin
        raw_url = content_for?(:url) ? content_for(:url) : request.original_url
        setting_current.canonical_url_for(raw_url)
      end
    end

    def canonical_url
      page_url.split("?").first.chomp("/")
    end

    def robots_content
      return "noindex, nofollow" if setting_current.site_indexing == "noindex"

      candidate = content_for?(:robots) ? content_for(:robots) : "index, follow"
      normalize_meta_text(candidate).presence || "index, follow"
    end

    def article_cover_for_seo(article)
      return unless article

      article if article.cover_image?
    end

    def article_schema(article)
      return unless article.respond_to?(:published_at) && article.published_at.present?

      schema = {
        "@context" => SCHEMA_CONTEXT,
        "@type" => article_schema_type(article),
        "headline" => schema_headline,
        "description" => page_description,
        "url" => page_url,
        "datePublished" => article.published_at.iso8601,
        "dateModified" => article.updated_at.iso8601,
        "author" => article_author_schema_people(article),
        "publisher" => {
          "@id" => schema_organization_id
        },
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => page_url
        },
        "articleSection" => article.categories.first&.name,
        "inLanguage" => schema_in_language
      }

      cover = article_cover_for_seo(article)
      if cover
        schema["image"] = {
          "@type" => "ImageObject",
          "url" => cover.cover_image.url,
          "width" => 1200,
          "height" => 630
        }
      end

      schema.compact
    end

    def author_schema(author)
      return unless author

      author_schema_person(author, include_works_for: true).merge("@context" => SCHEMA_CONTEXT)
    end

    def website_schema
      {
        "@context" => SCHEMA_CONTEXT,
        "@type" => "WebSite",
        "name" => schema_website_name,
        "url" => schema_site_root_url,
        "description" => schema_website_description,
        "inLanguage" => schema_in_language,
        "publisher" => { "@id" => schema_organization_id }
      }.compact
    end

    def organization_schema
      schema_publisher
    end

    def structured_data_graph(article: nil, author: nil, category: nil)
      graph = [website_schema, organization_schema]
      graph << article_schema(article) if article
      graph << author_schema(author) if author && !article
      graph << breadcrumbs_schema(article, category)

      {
        "@context" => SCHEMA_CONTEXT,
        "@graph" => graph.compact
      }
    end

    def breadcrumbs_schema(article, category)
      items = [{ name: I18n.t("postnhost.public.breadcrumbs.home"), url: schema_site_root_url }]

      if article&.categories&.any?
        items << { name: article.categories.first.name, url: postnhost.public_category_url(article.categories.first.slug) }
        items << { name: page_title, url: page_url }
      elsif category
        items << { name: category.name, url: page_url }
      elsif article
        items << { name: page_title, url: page_url }
      end

      {
        "@context" => SCHEMA_CONTEXT,
        "@type" => "BreadcrumbList",
        "itemListElement" => items.map.with_index do |item, index|
          {
            "@type" => "ListItem",
            "position" => index + 1,
            "name" => item[:name],
            "item" => item[:url]
          }
        end
      }
    end

    def structured_data_script(data, id: nil)
      content_tag :script, type: "application/ld+json", "data-turbo-track": "reload", id: id do
        data.to_json.html_safe
      end
    end

    private

    def omit_description_for_paginated_public_index?
      action_name == "index" &&
        %w[articles categories].include?(controller_name) &&
        params[:page].to_i > 1
    end

    def normalize_meta_text(value)
      strip_tags(value.to_s).squish
    end

    def article_author_schema_people(article)
      article_authors(article).map { |author| article_author_schema_person(author) }
    end

    def article_author_schema_person(author)
      author_schema_person(author).compact
    end

    def author_schema_person(author, include_works_for: false)
      schema = {
        "@type" => "Person",
        "@id" => author_profile_schema_id(author),
        "name" => author_schema_text(author, "name", author_name(author)),
        "jobTitle" => author_schema_text(author, "job_title", author.position.presence),
        "description" => author_schema_text(author, "bio", author.bio.presence),
        "url" => author_profile_url(author),
        "image" => author_image_schema(author),
        "sameAs" => author_same_as_links(author),
        "knowsAbout" => author_schema_array(author, "knows_about"),
        "knowsLanguage" => author_schema_knows_language(author),
        "awards" => author_schema_array(author, "awards")
      }

      alumni_name = author_schema_text(author, "alumni_of", "")
      if alumni_name.present?
        schema["alumniOf"] = {
          "@type" => author.schema_profile_value("alumni_type", default: "EducationalOrganization"),
          "name" => alumni_name
        }
      end

      schema["worksFor"] = { "@id" => schema_organization_id } if include_works_for
      schema.compact
    end

    def author_image_schema(author)
      avatar_url = author.schema_profile_value("image_url").presence || author_avatar(author)
      return if avatar_url.blank?

      {
        "@type" => "ImageObject",
        "url" => avatar_url,
        "width" => 128,
        "height" => 128
      }
    end

    def author_profile_url(author)
      return unless author_pages_enabled?

      "#{postnhost.public_author_url(author.slug).chomp('/')}/"
    end

    def author_profile_schema_id(author)
      profile_url = author_profile_url(author)
      return if profile_url.blank?

      "#{profile_url}#person"
    end

    def schema_publisher
      schema_organization_node.merge(
        "logo" => {
          "@type" => "ImageObject",
          "url" => setting_site_logo_absolute_url,
          "width" => 960,
          "height" => 198
        }
      ).compact
    end

    def schema_site_root_url
      setting_current.effective_site_url.presence || request.base_url
    end

    def schema_organization_id
      "#{schema_site_root_url}/#organization"
    end

    def schema_organization_node
      node = {
        "@type" => schema_settings_value("organization_type", "Organization"),
        "@id" => schema_organization_id,
        "name" => schema_organization_name,
        "alternateName" => schema_organization_alternate_name,
        "description" => schema_organization_description,
        "foundingDate" => schema_settings_value("founding_date"),
        "foundingLocation" => schema_settings_value("founding_location"),
        "url" => schema_site_root_url
      }

      contact_point = schema_organization_contact_point
      node["contactPoint"] = contact_point if contact_point.present?

      address = schema_organization_address
      node["address"] = address if address.present?

      same_as = schema_organization_same_as
      node["sameAs"] = same_as if same_as.any?

      policies = schema_organization_policies
      node.merge!(policies) if policies.present?

      coverage_start = schema_settings_value("coverage_starts_at")
      coverage_end = schema_settings_value("coverage_ends_at")
      node["coverageStartTime"] = coverage_start if coverage_start.present?
      node["coverageEndTime"] = coverage_end if coverage_end.present?

      node.compact
    end

    def schema_website_name
      schema_settings_object.schema_text_for(
        locale: current_schema_locale,
        key: "website_name",
        fallback: I18n.t("postnhost.public.site.schema_site_name")
      )
    end

    def schema_website_description
      schema_settings_object.schema_text_for(
        locale: current_schema_locale,
        key: "website_description",
        fallback: I18n.t("postnhost.public.site.blog_meta_description")
      )
    end

    def schema_organization_name
      schema_settings_object.schema_text_for(
        locale: current_schema_locale,
        key: "organization_name",
        fallback: schema_website_name
      )
    end

    def schema_organization_alternate_name
      schema_settings_object.schema_text_for(
        locale: current_schema_locale,
        key: "organization_alternate_name",
        fallback: nil
      )
    end

    def schema_organization_description
      schema_settings_object.schema_text_for(
        locale: current_schema_locale,
        key: "organization_description",
        fallback: schema_website_description
      )
    end

    def schema_organization_same_as
      schema_settings_value("same_as").to_a.map(&:to_s).compact_blank.uniq
    end

    def schema_organization_policies
      policies = schema_settings_object.schema_settings_hash.fetch("policies", {})
      policies.each_with_object({}) do |(key, value), memo|
        next if value.blank?

        camelized_key = key.to_s.split("_").each_with_index.map { |segment, idx| idx.zero? ? segment : segment.capitalize }.join
        memo[camelized_key] = value
      end
    end

    def schema_organization_contact_point
      email = schema_settings_value("contact_email")
      contact_type = schema_settings_value("contact_type")
      return if email.blank? && contact_type.blank?

      {
        "@type" => "ContactPoint",
        "email" => email,
        "contactType" => contact_type
      }.compact
    end

    def schema_organization_address
      street = schema_settings_value("address")
      city = schema_settings_value("address_city")
      country = schema_settings_value("address_country")
      return if street.blank? && city.blank? && country.blank?

      {
        "@type" => "PostalAddress",
        "streetAddress" => street,
        "addressLocality" => city,
        "addressCountry" => country
      }.compact
    end

    def article_schema_type(article)
      article_type = article.respond_to?(:schema_article_type) ? article.schema_article_type : nil
      return article_type if article_type.present?

      schema_settings_value("default_article_type", "BlogPosting")
    end

    def author_schema_text(author, key, fallback)
      author.schema_text_for(locale: current_schema_locale, key:, fallback:)
    end

    def author_schema_array(author, key)
      value = author_schema_text(author, key, "")
      schema_multiline_to_array(value)
    end

    def author_same_as_links(author)
      profile_links = author.schema_profile_value("same_as").to_a.map(&:to_s).compact_blank
      social_links = author_social_links(author).pluck(:url)

      (profile_links + social_links).uniq
    end

    def author_schema_knows_language(author)
      author.schema_profile_value("knows_language").to_a.map(&:to_s).compact_blank.uniq
    end

    def schema_settings_value(key, default = nil)
      schema_settings_object.schema_setting(key, default:)
    end

    def schema_settings_object
      @schema_settings_object ||= setting_current
    end

    def current_schema_locale
      locale = if content_for?(:lang)
                 content_for(:lang)
               elsif respond_to?(:current_language)
                 current_language&.html_lang
               else
                 I18n.locale.to_s
               end
      locale.to_s
    end

    def schema_in_language
      current_schema_locale.presence || DEFAULT_LANGUAGE
    end
  end
end

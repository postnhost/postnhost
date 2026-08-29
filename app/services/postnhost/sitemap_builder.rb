module Postnhost
  class SitemapBuilder
    include Postnhost::Engine.routes.url_helpers

    SITEMAP_NAMESPACE = "http://www.sitemaps.org/schemas/sitemap/0.9"
    XHTML_NAMESPACE = "http://www.w3.org/1999/xhtml"
    CACHE_VERSION = "sitemap_xml_v12"

    def initialize(request:, site_url:)
      @request = request
      @site_url = site_url
    end

    def cache_key
      [
        CACHE_VERSION,
        site_url,
        request.script_name.presence,
        Postnhost::PublicSiteRevision.current.revision,
        static_pages_signature
      ].compact.join(":")
    end

    def call
      doc = Nokogiri::XML(build_xml_string)
      pretty = doc.to_xml(indent: 2, indent_text: " ")
      insert_stylesheet_pi(pretty)
    end

    private

    attr_reader :request, :site_url

    def build_xml_string
      Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.urlset("xmlns" => SITEMAP_NAMESPACE, "xmlns:xhtml" => XHTML_NAMESPACE) do
          sitemap_entries.each do |entry|
            xml.url do
              xml.loc entry[:loc]
              xml.lastmod entry[:lastmod].utc.iso8601 if entry[:lastmod].present?

              entry[:alternates].each do |alternate|
                xml["xhtml"].link(rel: "alternate", hreflang: alternate[:hreflang], href: alternate[:href])
              end
            end
          end
        end
      end.to_xml
    end

    # Browsers may use this PI for presentation; crawlers fetch the same XML bytes and ignore styling.
    def insert_stylesheet_pi(xml)
      xml.sub(/\A<\?xml[^?]*\?>/m) do |decl|
        %(#{decl}\n<?xml-stylesheet type="text/xsl" href="#{stylesheet_href}"?>)
      end
    end

    def stylesheet_href
      script = request.script_name.to_s.chomp("/")
      return "/sitemap.xsl" if script.blank?

      "#{script}/sitemap.xsl"
    end

    def sitemap_entries
      @sitemap_entries ||= [
        *blog_index_entries,
        *category_page_entries,
        *article_page_entries,
        *static_page_entries
      ]
    end

    def blog_index_entries
      urls = []
      default_href = nil

      if default_language_present_for_root?
        default_href = absolute_url(root_path(script_name: request.script_name))
        urls << { hreflang: default_language_code, href: default_href }
      end

      localized_root_languages.each do |language|
        urls << {
          hreflang: language.html_lang,
          href: absolute_url(localized_root_path(locale: language.html_lang, script_name: request.script_name))
        }
      end

      build_cluster_entries(urls:, lastmod: latest_public_content_updated_at, x_default_href: default_href)
    end

    def category_page_entries
      public_categories.flat_map do |category|
        urls = []
        default_href = nil

        if category_present_for_default_language?(category)
          default_href = absolute_url(public_category_path(category.slug, script_name: request.script_name))
          urls << { hreflang: default_language_code, href: default_href }
        end

        localized_category_languages(category).each do |language|
          urls << {
            hreflang: language.html_lang,
            href: absolute_url(
              localized_public_category_path(language.html_lang, category.slug, script_name: request.script_name)
            )
          }
        end

        build_cluster_entries(
          urls:,
          lastmod: category_last_modified_at(category),
          x_default_href: default_href
        )
      end
    end

    def article_page_entries
      public_articles.order(:slug).flat_map do |article|
        next [] if category_slugs.include?(article.slug)

        urls = []
        article_language_code = article.language&.html_lang || default_language_code

        urls << {
          hreflang: article_language_code,
          href: absolute_url(public_article_path(article.slug, script_name: request.script_name))
        }

        public_variants_by_article_id.fetch(article.article_id, []).each do |variant|
          next if variant.language.html_lang == article_language_code

          urls << {
            hreflang: variant.language.html_lang,
            href: absolute_url(
              localized_public_article_path(locale: variant.language.html_lang, slug: article.slug, script_name: request.script_name)
            )
          }
        end

        build_cluster_entries(urls:, lastmod: article_last_modified_at(article), x_default_href: urls.first&.dig(:href))
      end
    end

    def static_page_entries
      [
        *static_template_entries,
        *dynamic_page_entries
      ]
    end

    def static_template_entries
      static_page_templates.filter_map do |slug, lastmod|
        next if reserved_static_slug?(slug)

        href = absolute_url(public_static_page_path(slug:, script_name: request.script_name))
        build_cluster_entries(
          urls: [{ hreflang: default_language_code, href: }],
          lastmod:,
          x_default_href: href
        )
      end.flatten
    end

    def dynamic_page_entries
      published_pages.filter_map do |page|
        slug = page.slug
        next if slug.blank? || reserved_static_slug?(slug)

        urls = []
        page_language_code = page.language&.html_lang || default_language_code

        urls << {
          hreflang: page_language_code,
          href: absolute_url(public_static_page_path(slug:, script_name: request.script_name))
        }

        public_page_variants_by_page_id.fetch(page.page_id, []).each do |variant|
          next if variant.language.html_lang == page_language_code

          urls << {
            hreflang: variant.language.html_lang,
            href: absolute_url(
              localized_public_static_page_path(locale: variant.language.html_lang, slug:, script_name: request.script_name)
            )
          }
        end

        build_cluster_entries(urls:, lastmod: page_last_modified_at(page), x_default_href: urls.first&.dig(:href))
      end.flatten
    end

    def page_last_modified_at(page)
      [page.updated_at, public_page_variants_by_page_id.fetch(page.page_id, []).map(&:updated_at).max].compact.max
    end

    def build_cluster_entries(urls:, lastmod:, x_default_href: nil)
      return [] if urls.blank?

      unique_urls = urls.uniq { |url| url[:hreflang] }
      alternates = unique_urls.dup
      alternates << { hreflang: "x-default", href: x_default_href } if x_default_href.present?

      unique_urls.map do |url|
        {
          loc: url[:href],
          lastmod:,
          alternates:
        }
      end
    end

    def absolute_url(path)
      "#{site_url}#{path}"
    end

    def latest_public_content_updated_at
      [public_articles.maximum(:updated_at), public_variants.maximum(:updated_at)].compact.max
    end

    def article_last_modified_at(article)
      [article.updated_at, public_variants_by_article_id.fetch(article.article_id, []).map(&:updated_at).max].compact.max
    end

    def category_last_modified_at(category)
      [category.updated_at, latest_default_category_article_update(category), latest_localized_category_variant_update(category)].compact.max
    end

    def latest_default_category_article_update(category)
      default_category_article_updated_at_by_category_id[category.id]
    end

    def latest_localized_category_variant_update(category)
      localized_category_variant_updated_at_by_category_id[category.id]
    end

    def default_language_present_for_root?
      default_public_articles.exists?
    end

    def category_present_for_default_language?(category)
      default_category_ids.include?(category.id)
    end

    def localized_root_languages
      all_non_default_languages.select { |language| localized_root_language_ids.include?(language.id) }
    end

    def localized_category_languages(category)
      language_ids = localized_category_language_ids_by_category_id[category.id] || Set.new
      all_non_default_languages.select { |language| language_ids.include?(language.id) }
    end

    def public_articles
      @public_articles ||= Postnhost::Snapshot::Article.includes(:language)
    end

    def public_variants
      @public_variants ||= Postnhost::Snapshot::ArticleVariant
                           .joins(:article_snapshot)
                           .includes(:language)
    end

    def default_public_articles
      @default_public_articles ||= if default_language.present?
                                     public_articles.where(language: default_language)
                                   else
                                     Postnhost::Article.none
                                   end
    end

    def public_categories
      @public_categories ||= Postnhost::Category
                             .joins(:article_snapshot_categories)
                             .distinct
                             .order(:slug)
    end

    def public_variants_by_article_id
      @public_variants_by_article_id ||= public_variants.group_by(&:article_id)
    end

    def all_languages
      @all_languages ||= begin
        languages = Postnhost::Language.order(:name).to_a
        default = default_language
        default.present? ? [default, *languages.reject { |language| language.id == default.id }] : languages
      end
    end

    def all_non_default_languages
      all_languages.reject { |language| language.id == default_language&.id }
    end

    def default_language
      @default_language ||= Postnhost::Language.blog_default
    end

    def default_language_code
      default_language&.html_lang || "en"
    end

    def static_page_templates
      @static_page_templates ||= begin
        templates = {}

        static_page_template_paths.each do |path|
          slug = File.basename(path, ".html.erb")
          templates[slug] = [templates[slug], File.mtime(path)].compact.max
        end

        templates.sort.to_h
      end
    end

    def static_page_template_paths
      [
        Rails.root.join("app/views/postnhost/static_pages/*.html.erb"),
        Postnhost::Engine.root.join("app/views/postnhost/static_pages/*.html.erb")
      ].flat_map { |pattern| Dir[pattern.to_s] }
    end

    def static_pages_signature
      static_page_templates.map { |slug, mtime| "#{slug}-#{mtime.utc.iso8601}" }.join(":")
    end

    def published_pages
      @published_pages ||= Postnhost::Snapshot::Page.where.not(slug: nil).includes(:language)
    end

    def public_page_variants
      @public_page_variants ||= Postnhost::Snapshot::PageVariant
                                .joins(:page_snapshot)
                                .includes(:language)
    end

    def public_page_variants_by_page_id
      @public_page_variants_by_page_id ||= public_page_variants.group_by(&:page_id)
    end

    def reserved_static_slug?(slug)
      category_slugs.include?(slug) || article_slugs.include?(slug)
    end

    def default_category_ids
      @default_category_ids ||= default_public_articles
                                .joins(:article_snapshot_categories)
                                .distinct
                                .pluck("postnhost_article_snapshot_categories.category_id")
                                .to_set
    end

    def localized_root_language_ids
      @localized_root_language_ids ||= public_variants.distinct.pluck(:language_id).to_set
    end

    def localized_category_language_ids_by_category_id
      @localized_category_language_ids_by_category_id ||= begin
        pairs = public_variants
                .joins(article_snapshot: :article_snapshot_categories)
                .distinct
                .pluck("postnhost_article_snapshot_categories.category_id", "postnhost_article_variant_snapshots.language_id")

        pairs.each_with_object({}) do |(category_id, language_id), hash|
          hash[category_id] ||= Set.new
          hash[category_id] << language_id
        end
      end
    end

    def default_category_article_updated_at_by_category_id
      @default_category_article_updated_at_by_category_id ||= default_public_articles
                                                              .joins(:article_snapshot_categories)
                                                              .group("postnhost_article_snapshot_categories.category_id")
                                                              .maximum(:updated_at)
    end

    def localized_category_variant_updated_at_by_category_id
      @localized_category_variant_updated_at_by_category_id ||= public_variants
                                                                .joins(article_snapshot: :article_snapshot_categories)
                                                                .group("postnhost_article_snapshot_categories.category_id")
                                                                .maximum("postnhost_article_variant_snapshots.updated_at")
    end

    def category_slugs
      @category_slugs ||= Postnhost::Category.where.not(slug: nil).distinct.pluck(:slug).to_set
    end

    def article_slugs
      @article_slugs ||= Postnhost::Snapshot::Article.where.not(slug: nil).distinct.pluck(:slug).to_set
    end
  end
end

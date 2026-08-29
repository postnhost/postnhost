module Postnhost
  class PublicRequestContext
    ENV_KEY = "postnhost.public_request_context"
    Resolution = Data.define(:kind, :record) do
      delegate :id, to: :record, prefix: true
    end

    def self.for(request)
      request.env[ENV_KEY] ||= new(request)
    end

    def initialize(request)
      @request = request
    end

    def setting
      @setting ||= Postnhost::Setting.current
    end

    def template_name
      @template_name ||= Postnhost::Template.active_name
    end

    def public_site_revision
      @public_site_revision ||= Postnhost::PublicSiteRevision.current
    end

    def requested_language
      return @requested_language if defined?(@requested_language)

      @requested_language = Postnhost::Language.find_by(html_lang: requested_locale) if requested_locale.present?
    end

    def default_language
      return @default_language if defined?(@default_language)

      @default_language = Postnhost::Language.blog_default
    end

    attr_writer :default_language

    def localized_language?
      requested_language.present? && !requested_language.default?
    end

    def resolve(slug)
      %i[category article page].each do |kind|
        resolution = resolve_kind(kind, slug)
        return resolution if resolution
      end

      nil
    end

    def resolve_kind(kind, slug)
      @resolutions ||= {}
      key = [kind, slug, requested_language&.id]
      return @resolutions[key] if @resolutions.key?(key)

      record = route_scope(kind).find_by(slug:)
      @resolutions[key] = record ? Resolution.new(kind:, record:) : nil
    end

    private

    attr_reader :request

    def requested_locale
      request.path_parameters[:locale].presence || request.params[:locale].presence
    end

    def route_scope(kind)
      case kind
      when :category then category_scope
      when :article then article_scope
      when :page then page_scope
      else raise ArgumentError, "Unknown public route kind: #{kind}"
      end
    end

    def category_scope
      Postnhost::Category.joins(:article_snapshot_categories)
    end

    def article_scope
      return Postnhost::Snapshot::Article.all unless localized_language?

      Postnhost::Snapshot::Article
        .joins(:article_variant_snapshots)
        .where(postnhost_article_variant_snapshots: { language_id: requested_language.id })
    end

    def page_scope
      return Postnhost::Snapshot::Page.all unless localized_language?

      Postnhost::Snapshot::Page
        .joins(:page_variant_snapshots)
        .where(postnhost_page_variant_snapshots: { language_id: requested_language.id })
    end
  end
end

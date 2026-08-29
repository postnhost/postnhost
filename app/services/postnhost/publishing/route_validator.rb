module Postnhost
  module Publishing
    class RouteValidator
      RESERVED_SLUGS = %w[authors search sitemap.xml sitemap.xsl].freeze

      def self.validate!(slug:, article_id: nil, page_id: nil)
        errors = []
        errors << "slug has already been published by an article" if article_conflict?(slug, article_id)
        errors << "slug has already been published by a page" if page_conflict?(slug, page_id)
        errors << "slug conflicts with a category route" if Postnhost::Category.exists?(slug:)
        errors << "slug conflicts with a static route" if static_slugs.include?(slug)
        raise Error, errors if errors.any?
      end

      def self.article_conflict?(slug, article_id)
        scope = Postnhost::Snapshot::Article.where(slug:)
        scope = scope.where.not(article_id:) if article_id
        scope.exists?
      end

      def self.page_conflict?(slug, page_id)
        scope = Postnhost::Snapshot::Page.where(slug:)
        scope = scope.where.not(page_id:) if page_id
        scope.exists?
      end

      def self.static_slugs
        @static_slugs ||= begin
          paths = [
            Rails.root.join("app/views/postnhost/static_pages/*.html.erb"),
            Postnhost::Engine.root.join("app/views/postnhost/static_pages/*.html.erb")
          ].flat_map { |pattern| Dir[pattern.to_s] }

          (RESERVED_SLUGS + paths.map { |path| File.basename(path, ".html.erb") }).to_set
        end
      end

      private_class_method :article_conflict?, :page_conflict?, :static_slugs
    end
  end
end

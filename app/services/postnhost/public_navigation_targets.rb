module Postnhost
  class PublicNavigationTargets < BaseService
    Targets = Data.define(:records, :variants)

    def initialize(items:, language:)
      @items = items
      @language = language
    end

    def call
      records = {
        "article" => article_snapshots,
        "page" => page_snapshots,
        "category" => categories
      }

      success(Targets.new(records:, variants: variants_for(records)))
    end

    private

    attr_reader :items, :language

    def target_ids(kind)
      items.filter_map { |item| item.target_id if item.kind == "link" && item.target_kind == kind }.uniq
    end

    def article_snapshots
      Postnhost::Snapshot::Article.where(article_id: target_ids("article")).index_by(&:article_id)
    end

    def page_snapshots
      Postnhost::Snapshot::Page.where(page_id: target_ids("page")).index_by(&:page_id)
    end

    def categories
      scope = category_scope
      scope = scope.includes(:category_variants) unless language.default?
      scope.distinct.index_by(&:id)
    end

    def category_scope
      scope = Postnhost::Category.where(id: target_ids("category"))
      return scope.joins(:article_snapshot_categories) if language.default?

      scope.joins(article_snapshot_categories: { article_snapshot: :article_variant_snapshots })
           .where(postnhost_article_variant_snapshots: { language_id: language.id })
    end

    def variants_for(records)
      return {} if language.default?

      {
        Postnhost::Snapshot::Article.name => article_variants(records.fetch("article")),
        Postnhost::Snapshot::Page.name => page_variants(records.fetch("page"))
      }
    end

    def article_variants(articles)
      Postnhost::Snapshot::ArticleVariant.where(article_id: articles.keys, language:).index_by(&:article_id)
    end

    def page_variants(pages)
      Postnhost::Snapshot::PageVariant.where(page_id: pages.keys, language:).index_by(&:page_id)
    end
  end
end

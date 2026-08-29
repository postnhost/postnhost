# rubocop:disable-next Metrics/BlockLength
namespace :postnhost do
  namespace :snapshots do
    desc "Audit snapshots for hard-cutover integrity"
    task audit: :environment do
      errors = []
      check = lambda do |snapshot, label|
        version = snapshot.paper_trail_version
        errors << "#{label}: missing paper-trail version" unless version
        errors << "#{label}: language is missing" unless snapshot.language
        expected_type = {
          Postnhost::Snapshot::Article => "Postnhost::Article",
          Postnhost::Snapshot::Page => "Postnhost::Page",
          Postnhost::Snapshot::ArticleVariant => "Postnhost::ArticleVariant",
          Postnhost::Snapshot::PageVariant => "Postnhost::PageVariant"
        }.fetch(snapshot.class)
        expected_id = case snapshot
                      when Postnhost::Snapshot::Article
                        snapshot.article_id
                      when Postnhost::Snapshot::Page
                        snapshot.page_id
                      when Postnhost::Snapshot::ArticleVariant
                        snapshot.article_variant_id
                      when Postnhost::Snapshot::PageVariant
                        snapshot.page_variant_id
                      end

        if version
          errors << "#{label}: version item_type mismatch (#{version.item_type})" unless version.item_type == expected_type
          errors << "#{label}: version item_id mismatch (#{version.item_id})" unless version.item_id == expected_id
        end
      rescue StandardError => e
        errors << "#{label}: #{e.message}"
      end

      Postnhost::Snapshot::Article.includes(:article, :language, :paper_trail_version).find_each do |snapshot|
        check.call(snapshot, "Snapshot::Article #{snapshot.id}")
        errors << "Snapshot::Article #{snapshot.id}: article missing" unless snapshot.article
        if snapshot.cover_image_identifier.present?
          image = Postnhost::PublishedCoverImage.new(article_id: snapshot.article_id, identifier: snapshot.cover_image_identifier)
          errors << "Snapshot::Article #{snapshot.id}: cover image #{snapshot.cover_image_identifier} is missing" unless image.send(:uploader).file&.exists?
        end
      end

      Postnhost::Snapshot::Page.includes(:page, :language, :paper_trail_version).find_each do |snapshot|
        check.call(snapshot, "Snapshot::Page #{snapshot.id}")
        errors << "Snapshot::Page #{snapshot.id}: page missing" unless snapshot.page
      end

      Postnhost::Snapshot::ArticleVariant.includes(:article_variant, :language, :paper_trail_version).find_each do |snapshot|
        check.call(snapshot, "Snapshot::ArticleVariant #{snapshot.id}")
        errors << "Snapshot::ArticleVariant #{snapshot.id}: article missing" unless snapshot.article
        errors << "Snapshot::ArticleVariant #{snapshot.id}: article_variant missing" unless snapshot.article_variant
      end

      Postnhost::Snapshot::PageVariant.includes(:page_variant, :language, :paper_trail_version).find_each do |snapshot|
        check.call(snapshot, "Snapshot::PageVariant #{snapshot.id}")
        errors << "Snapshot::PageVariant #{snapshot.id}: page missing" unless snapshot.page
        errors << "Snapshot::PageVariant #{snapshot.id}: page_variant missing" unless snapshot.page_variant
      end

      article_slugs = Postnhost::Snapshot::Article.pluck(:slug)
      page_slugs = Postnhost::Snapshot::Page.pluck(:slug)
      (article_slugs & page_slugs).each { |slug| errors << "Published article/page slug collision: #{slug}" }

      default_languages = Postnhost::Language.where(default: true).count
      errors << "Expected exactly one default language, found #{default_languages}" unless default_languages == 1

      if errors.none?
        puts "Snapshot audit passed."
      else
        warn errors.map { |error| "- #{error}" }.join("\n")
        abort "Snapshot audit failed with #{errors.count} error(s)."
      end
    end
  end
end

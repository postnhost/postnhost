module Postnhost
  module Management
    module Serializer
      SUMMARY_FIELDS = %w[
        id user_id article_id page_id category_id language_id name title slug email position
        html_lang default created_at updated_at scheduled_at publication_error top_pick generating
        articles_count article_variants_count page_variants_count placement revoked_at
        cover_image cover_image_alt avatar_file
      ].freeze

      def self.summary(record)
        data = record.attributes.slice(*SUMMARY_FIELDS)
        data["published"] = record["management_snapshot_id"].present? if record.has_attribute?("management_snapshot_id")
        %w[cover_image avatar_file].each do |field|
          data["#{field}_url"] = record.public_send(field).url if record.has_attribute?(field)
        end
        data
      end

      def self.call(value)
        case value
        when ActiveRecord::Base
          data = value.attributes.except("password_digest", "token_digest", "scheduled_job_id")
          if value.respond_to?(:published?)
            data["published"] = value.published?
            data["unpublished_changes"] = value.unpublished_changes?
          end
          data.merge!("author_ids" => value.author_ids, "category_ids" => value.category_ids, "suggested_article_ids" => value.suggested_article_ids) if value.is_a?(Article)
          %w[cover_image avatar_file site_logo og_image].each do |field|
            data["#{field}_url"] = value.public_send(field).url if value.respond_to?(field)
          end
          data
        when Hash then value.transform_values { |item| call(item) }
        when Array then value.map { |item| call(item) }
        else value
        end
      end
    end
  end
end

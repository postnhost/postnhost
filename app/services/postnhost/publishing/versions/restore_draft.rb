module Postnhost
  module Publishing
    class Versions::RestoreDraft < BaseService
      ATTRIBUTES = {
        "Postnhost::Article" => %i[
          title title_tag og_title schema_headline schema_article_type meta_description custom_excerpt
          use_excerpt_as_meta_description content slug cover_image_alt cover_image
        ],
        "Postnhost::ArticleVariant" => %i[
          title title_tag og_title schema_headline meta_description custom_excerpt use_excerpt_as_meta_description content
        ],
        "Postnhost::Page" => %i[title title_tag og_title meta_description content slug],
        "Postnhost::PageVariant" => %i[title title_tag og_title meta_description content]
      }.freeze

      def initialize(record:, version:)
        @record = record
        @version = version
      end

      def call
        restored = record.class.transaction do
          record.lock!
          restore_locked!
        end
        success(restored, status: :ok)
      rescue Error => e
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid => e
        failure(e.message)
      end

      def restore_locked!
        validate_version!
        versioned = version.reify
        raise Error, "Version cannot be restored" unless versioned

        attributes.each do |attribute|
          if attribute == :cover_image
            record.write_attribute(:cover_image, versioned.cover_image.identifier.presence)
          else
            record.public_send("#{attribute}=", versioned.public_send(attribute))
          end
        end
        record.save!
        record
      end

      private

      attr_reader :record, :version

      def attributes
        ATTRIBUTES.fetch(record.class.name) { raise Error, "Unsupported snapshot record type" }
      end

      def validate_version!
        return if version.is_a?(Postnhost::Version) && version.item_type == record.class.name && version.item_id == record.id

        raise Error, "Version does not belong to this record"
      end
    end
  end
end

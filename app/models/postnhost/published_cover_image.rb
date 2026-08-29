module Postnhost
  class PublishedCoverImage
    attr_reader :identifier

    def initialize(article_id:, identifier:)
      @article_id = article_id
      @identifier = identifier.presence
    end

    delegate :present?, to: :identifier

    delegate :url, to: :uploader

    delegate :thumbnail, to: :uploader

    delegate :medium, to: :uploader

    private

    attr_reader :article_id

    def uploader
      @uploader ||= CoverImageUploader.new(Article.new(id: article_id), :cover_image).tap do |mounted_uploader|
        mounted_uploader.retrieve_from_store!(identifier) if identifier.present?
      end
    end
  end
end

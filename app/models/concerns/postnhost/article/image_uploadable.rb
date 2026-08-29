module Postnhost::Article::ImageUploadable
  extend ActiveSupport::Concern

  include Postnhost::InlineImageUploadable

  private

  def inline_image_uploader_class
    Postnhost::InlineArticleImageUploader
  end
end

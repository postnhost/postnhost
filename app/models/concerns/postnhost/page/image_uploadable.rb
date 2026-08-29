module Postnhost::Page::ImageUploadable
  extend ActiveSupport::Concern

  include Postnhost::InlineImageUploadable

  private

  def inline_image_uploader_class
    Postnhost::InlinePageImageUploader
  end
end

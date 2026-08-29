module Postnhost::InlineImageUploadable
  extend ActiveSupport::Concern

  IMAGE_MAX_SIZE = 20.megabytes
  SUPPORTED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp image/heic].freeze

  def upload_inline_image(file)
    return { success: false, error: "Invalid file type" } unless valid_image_file_type?(file)
    return { success: false, error: "File too large" } if image_file_too_large?(file)

    uploader = inline_image_uploader_class.new(self, :inline_image)
    uploader.store!(file)

    {
      success: true,
      url: uploader.url,
      filename: uploader.identifier
    }
  rescue CarrierWave::ProcessingError, CarrierWave::IntegrityError => e
    Rails.logger.error("CarrierWave inline image error: #{e.message}")
    { success: false, error: "Invalid image file" }
  rescue StandardError => e
    Rails.logger.error("Inline image processing error: #{e.message}")
    { success: false, error: "Error processing image" }
  end

  private

  def valid_image_file_type?(file)
    SUPPORTED_CONTENT_TYPES.include?(file.content_type)
  end

  def image_file_too_large?(file)
    file.size > IMAGE_MAX_SIZE
  end

  def inline_image_uploader_class
    raise NotImplementedError, "including class must define #inline_image_uploader_class"
  end
end

module Postnhost
  class InlinePageImageUploader < ::BaseUploader
    MAX_WIDTH = 1200
    QUALITY = 90

    process resize_to_limit: [MAX_WIDTH, nil]
    process convert: "webp"
    process :quality

    def store_dir
      "uploads/pages/#{model.user_id}/#{model.id}/inline_images"
    end

    def size_range
      0..(20.megabytes)
    end

    def extension_allowlist
      %w[png jpg jpeg gif webp heic]
    end

    def quality
      vips! do |v|
        v.saver(Q: QUALITY)
      end
    end

    def filename
      generated_filename
    end

    private

    def generated_filename
      @generated_filename ||= "#{SecureRandom.hex(12)}.webp"
    end
  end
end

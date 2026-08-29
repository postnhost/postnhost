class CoverImageUploader < BaseUploader
  QUALITY = 90

  self.remove_previously_stored_files_after_update = false

  process resize_to_fill: [1200, 630]
  process convert: "webp"
  process :quality

  version :thumbnail do
    process resize_to_fill: [780, 410]
    process convert: "webp"
    process :quality
  end

  version :medium do
    process resize_to_fill: [1024, 537]
    process convert: "webp"
    process :quality
  end

  def quality
    vips! do |v|
      v.saver(Q: QUALITY)
    end
  end

  def extension_allowlist
    %w[png jpg jpeg gif webp heic]
  end
end

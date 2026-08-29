module Postnhost
  class SettingAssetUploader < ::BaseUploader
    QUALITY = 100

    process convert: "webp"
    process :quality

    def quality
      vips! do |v|
        v.saver(Q: QUALITY)
      end
    end

    def extension_allowlist
      %w[png jpg jpeg gif webp heic]
    end
  end
end

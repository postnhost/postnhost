module Postnhost
  class AvatarUploader < ::BaseUploader
    process resize_to_limit: [200, 200]
    process convert: "webp"
    process :quality

    def quality
      vips! do |v|
        v.saver(Q: 90)
      end
    end

    def extension_allowlist
      %w[png jpg jpeg gif webp heic]
    end
  end
end

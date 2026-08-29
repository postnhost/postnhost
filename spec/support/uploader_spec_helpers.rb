require "vips"

module UploaderSpecHelpers
  def with_isolated_uploader_root
    root = Rails.root.join("tmp/uploads-spec")
    FileUtils.rm_rf(root)

    previous_roots = uploader_classes.index_with(&:root)
    previous_processing = uploader_classes.index_with(&:enable_processing)

    uploader_classes.each do |klass|
      klass.root = root
      klass.enable_processing = true
    end

    yield root
  ensure
    uploader_classes.each do |klass|
      klass.root = previous_roots[klass]
      klass.enable_processing = previous_processing[klass]
    end
    FileUtils.rm_rf(root) if root
  end

  def uploaded_image(path, content_type)
    Rack::Test::UploadedFile.new(path.to_s, content_type)
  end

  def postnhost_asset_image_path(filename)
    Postnhost::Engine.root.join("app/assets/images/postnhost/#{filename}")
  end

  def dummy_public_image_path(filename)
    Postnhost::Engine.root.join("spec/dummy/public/#{filename}")
  end

  def image_dimensions(path)
    image = Vips::Image.new_from_file(path.to_s)
    [image.width, image.height]
  end

  def hashed_store_dir(model, mounted_as)
    data = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    hash = Digest::SHA256.hexdigest(data)
    "uploads/#{model.class.to_s.underscore}/#{hash[0..20]}"
  end

  def hashed_webp_filename(model, mounted_as, time)
    data = "#{model.id}-#{mounted_as}-#{time.to_i}"
    hash = Digest::SHA256.hexdigest(data)
    "#{hash[0..12]}.webp"
  end

  private

  def uploader_classes
    [
      ::BaseUploader,
      ::CoverImageUploader,
      Postnhost::AvatarUploader,
      Postnhost::InlineArticleImageUploader,
      Postnhost::InlinePageImageUploader,
      Postnhost::SettingAssetUploader
    ]
  end
end

RSpec.configure do |config|
  config.include UploaderSpecHelpers
end

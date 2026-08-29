class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::Vips

  def store_dir
    data = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    hash = Digest::SHA256.hexdigest(data)
    "uploads/#{model.class.to_s.underscore}/#{hash[0..20]}"
  end

  def size_range
    0..(25.megabytes)
  end

  def filename
    generated_filename
  end

  private

  def generated_filename
    data = "#{model.id}-#{mounted_as}-#{Time.current.to_i}"
    hash = Digest::SHA256.hexdigest(data)
    extension = "webp"
    @generated_filename ||= "#{hash[0..12]}.#{extension}"
  end
end

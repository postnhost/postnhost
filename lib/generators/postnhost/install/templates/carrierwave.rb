CarrierWave.configure do |config|
  if Rails.env.production?
    config.storage = :aws
    config.aws_bucket = Postnhost.config.aws_bucket
    config.aws_acl = "public-read"

    config.aws_credentials = {
      access_key_id: Postnhost.config.aws_access_key_id,
      secret_access_key: Postnhost.config.aws_secret_access_key,
      region: Postnhost.config.aws_region,
      endpoint: Postnhost.config.aws_endpoint_url_s3,
      stub_responses: Rails.env.test?
    }
  else
    config.storage = :file
  end
end

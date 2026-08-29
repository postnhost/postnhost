Postnhost.configure do |config|
  # ==> Site defaults
  # Used when the matching Dashboard → Settings → Site field is blank.
  # config.site_url = "https://example.com"
  # config.public_page_size = 12

  # ==> Integrations
  # Default admin timezone used for scheduling and timestamp display
  # config.default_timezone = 'UTC'

  # OpenAI API key for AI translations.
  # Explicit config value takes priority over credentials fallback.
  # config.openai_api_key = "sk-..."
  # config.openai_gpt_model = "gpt-5.4-mini"

  # ==> AWS/S3 (CarrierWave uploads)
  # Explicit config values take priority over credentials fallback:
  # config.aws_access_key_id = "AKIA..."
  # config.aws_secret_access_key = "..."
  # config.aws_region = "us-east-1"
  # config.aws_bucket = "my-bucket"
  # config.aws_endpoint_url_s3 = "https://fly.storage.tigris.dev"
  #
  # Encrypted credentials (alternative to explicit settings):
  #   postnhost:
  #     openai_access_token: sk-...
  #     openai_gpt_model: gpt-5.4-mini
  #     aws_access_key_id: AKIA...
  #     aws_secret_access_key: ...
  #     aws_region: us-east-1
  #     aws_bucket_name: my-bucket
  #     aws_endpoint_url_s3: https://fly.storage.tigris.dev
  #
  # Litestream (SQLite backups) is not configured here — use host app
  # config/initializers/litestream.rb + credentials (see engine README).
end

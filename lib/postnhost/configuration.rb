require "uri"

module Postnhost
  class Configuration
    PUBLIC_PAGE_SIZE_RANGE = (1..100)

    # Integrations
    attr_accessor :openai_api_key, :openai_gpt_model, :default_timezone

    # Site defaults
    attr_reader :site_url, :public_page_size

    # AWS/S3 Storage
    attr_accessor :aws_access_key_id, :aws_secret_access_key,
                  :aws_region, :aws_bucket, :aws_endpoint_url_s3

    def initialize
      # Integrations
      @default_timezone = rails_default_timezone
      @site_url = nil
      @public_page_size = 12
      @openai_api_key = credentials_dig(:postnhost, :openai_access_token)
      @openai_gpt_model = credentials_dig(:postnhost, :openai_gpt_model)
      # AWS/S3 (from Rails credentials)
      @aws_access_key_id = credentials_dig(:postnhost, :aws_access_key_id)
      @aws_secret_access_key = credentials_dig(:postnhost, :aws_secret_access_key)
      @aws_region = credentials_dig(:postnhost, :aws_region)
      @aws_bucket = credentials_dig(:postnhost, :aws_bucket_name)
      @aws_endpoint_url_s3 = credentials_dig(:postnhost, :aws_endpoint_url_s3)
    end

    def site_url=(value)
      if value.blank?
        @site_url = nil
        return
      end

      normalized_url = value.to_s.strip.chomp("/")
      uri = URI.parse(normalized_url)
      raise ArgumentError, "site_url must be an HTTP(S) origin without a path, query, or fragment" unless uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil? && uri.path.blank? && uri.query.nil? && uri.fragment.nil?

      @site_url = normalized_url
    rescue URI::InvalidURIError
      raise ArgumentError, "site_url must be a valid URL"
    end

    def public_page_size=(value)
      page_size = Integer(value, exception: false)
      raise ArgumentError, "public_page_size must be an integer between 1 and 100" unless page_size && PUBLIC_PAGE_SIZE_RANGE.cover?(page_size)

      @public_page_size = page_size
    end

    private

    def credentials_dig(*keys)
      Rails.application.credentials.dig(*keys)
    end

    def rails_default_timezone
      Rails.application.config.time_zone.presence || "UTC"
    end
  end
end

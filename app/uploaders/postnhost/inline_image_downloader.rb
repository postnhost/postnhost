module Postnhost
  class InlineImageDownloader < CarrierWave::Downloader::Base
    def download(url)
      request = nil
      response = SsrfFilter.get(
        process_uri(url),
        scheme_whitelist: %w[http https],
        http_options: { open_timeout: 5, read_timeout: 10 },
        request_proc: ->(value) { request = value }
      ) do |result|
        body = +"".b
        result.read_body do |chunk|
          raise CarrierWave::DownloadError, "File too large" if body.bytesize + chunk.bytesize > InlineImageUploadable::IMAGE_MAX_SIZE

          body << chunk
        end
        result.body = body
      end
      response.value
      response.uri = request.uri
      CarrierWave::Downloader::RemoteFile.new(response)
    rescue StandardError => e
      raise CarrierWave::DownloadError, e.message
    end
  end
end

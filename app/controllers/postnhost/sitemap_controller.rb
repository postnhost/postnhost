module Postnhost
  class SitemapController < ApplicationController
    def show
      sitemap_builder = Postnhost::SitemapBuilder.new(request:, site_url: current_setting.effective_site_url.presence || request.base_url)
      sitemap_xml = Rails.cache.fetch(sitemap_builder.cache_key, expires_in: 1.hour) do
        sitemap_builder.call
      end

      render xml: sitemap_xml
    end

    def stylesheet
      path = Postnhost::Engine.root.join("app/assets/xsl/sitemap.xsl")
      send_file path, type: "application/xslt+xml", disposition: "inline"
    end
  end
end

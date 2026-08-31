module Postnhost
  module Generators
    class StaticPagesGenerator < Rails::Generators::Base
      argument :slugs, type: :array, default: [], banner: "slug [slug ...]"

      desc "Creates static page templates in app/views/postnhost/static_pages"

      def create_static_pages
        if slugs.empty?
          say("Please provide at least one page slug, e.g. bin/rails g postnhost:static_pages terms privacy", :red)
          return
        end

        slugs.each do |raw_slug|
          slug = raw_slug.to_s.strip
          unless valid_slug?(slug)
            say("Skipping invalid slug '#{raw_slug}'. Use lowercase letters, numbers, underscores, or hyphens.", :yellow)
            next
          end

          title = slug.tr("_-", " ").split.map(&:capitalize).join(" ")
          create_file "app/views/postnhost/static_pages/#{slug}.html.erb", static_page_template(slug, title)
        end
      end

      private

      def valid_slug?(slug)
        slug.match?(/\A[a-z0-9_-]+\z/)
      end

      def static_page_template(slug, title)
        <<~ERB
          <% content_for :title, "#{title}" %>
          <% content_for :meta_description, "#{title} page" %>

          <div class="max-w-4xl mx-auto px-4 py-12">
            <h1 class="text-3xl font-bold text-gray-900 mb-4">#{title}</h1>
            <p class="text-gray-700">
              Replace this template content in <code>app/views/postnhost/static_pages/#{slug}.html.erb</code>.
            </p>
          </div>
        ERB
      end
    end
  end
end

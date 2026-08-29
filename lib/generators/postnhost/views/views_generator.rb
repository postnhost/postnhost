module Postnhost
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc "Copies public Postnhost views to your application for customization"
      class_option :views_scope,
                   type: :string,
                   required: true,
                   enum: %w[minimal full],
                   desc: "Choose copied view scope: minimal (clean style-focused views) or full (all views and helper partials)."

      def copy_views
        copy_public_views
      end

      private

      def copy_public_views
        say "Copying public views...", :green
        copy_public_views_by_scope
        copy_template_public_views
        copy_public_template_layouts
        copy_shared_content_for_partials
        copy_full_scope_shared_public_partials
        copy_file "layouts/postnhost/_footer.html.erb", "app/views/layouts/postnhost/_footer.html.erb"
        copy_file "layouts/postnhost/_favicon.html.erb", "app/views/layouts/postnhost/_favicon.html.erb"
        copy_file "layouts/postnhost/public_header/_logo.html.erb", "app/views/layouts/postnhost/public_header/_logo.html.erb"
        copy_file "layouts/postnhost/public_header/_language_switcher.html.erb", "app/views/layouts/postnhost/public_header/_language_switcher.html.erb"
        copy_file "layouts/postnhost/public_header/_dashboard_sign_in.html.erb", "app/views/layouts/postnhost/public_header/_dashboard_sign_in.html.erb"
        say ""
        warn_if_host_tailwind_not_installed
        say "Public views copied (#{views_scope})! Full scope includes every public template and layout under app/views/postnhost/public/templates/ and app/views/layouts/postnhost/public/templates/.", :green
      end

      def engine_views_path
        Postnhost::Engine.root.join("app/views")
      end

      def copy_public_views_by_scope
        return copy_default_template_public_views if full_scope?

        copy_minimal_public_views
      end

      def copy_full_scope_shared_public_partials
        return unless full_scope?

        copy_file "postnhost/shared/_seo_meta_tags.html.erb", "app/views/postnhost/shared/_seo_meta_tags.html.erb"
        copy_file "postnhost/shared/_structured_data.html.erb", "app/views/postnhost/shared/_structured_data.html.erb"
      end

      def copy_minimal_public_views
        default_template_public_view_mappings.each do |source_path, destination_path|
          copy_file source_path, File.join("app/views", destination_path)
        end
      end

      def copy_default_template_public_views
        default_template_public_view_mappings.each do |source_path, destination_path|
          copy_file source_path, File.join("app/views", destination_path)
        end
      end

      def copy_template_public_views
        return unless full_scope?

        template_public_view_files.each do |relative_path|
          copy_file relative_path, File.join("app/views", relative_path)
        end
      end

      def copy_public_template_layouts
        return unless full_scope?

        public_template_layout_files.each do |relative_path|
          copy_file relative_path, File.join("app/views", relative_path)
        end
      end

      def copy_shared_content_for_partials
        return unless full_scope?

        shared_content_for_files.each do |relative_path|
          copy_file relative_path, File.join("app/views", relative_path)
        end
      end

      def default_template_public_view_mappings
        Dir.glob(engine_views_path.join("postnhost/public/templates/default/**/*.erb")).map do |path|
          source_path = Pathname.new(path).relative_path_from(engine_views_path).to_s
          destination_path = source_path
          [source_path, destination_path]
        end
      end

      def shared_content_for_files
        Dir.glob(engine_views_path.join("postnhost/public/**/content_for/**/*.erb")).map do |path|
          Pathname.new(path).relative_path_from(engine_views_path).to_s
        end
      end

      def template_public_view_files
        template_files = Dir.glob(engine_views_path.join("postnhost/public/templates/**/*.erb")).map do |path|
          Pathname.new(path).relative_path_from(engine_views_path).to_s
        end

        template_files.reject { |path| path.start_with?("postnhost/public/templates/default/") }
      end

      def public_template_layout_files
        Dir.glob(engine_views_path.join("layouts/postnhost/public/templates/*.erb")).map do |path|
          Pathname.new(path).relative_path_from(engine_views_path).to_s
        end
      end

      def full_scope?
        views_scope == "full"
      end

      def views_scope
        options[:views_scope]
      end

      def warn_if_host_tailwind_not_installed
        return if host_tailwind_enabled?

        say "Tip: if you add new Tailwind classes in copied views, install host pipeline:", :yellow
        say "  rails g postnhost:tailwindcss:install"
        say "  bundle exec rails postnhost:tailwindcss:watch"
        say ""
      end

      def host_tailwind_enabled?
        Rails.root.join("postnhost.tailwind.config.js").exist? &&
          Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css").exist?
      end

      def source_paths
        [engine_views_path.to_s]
      end
    end
  end
end

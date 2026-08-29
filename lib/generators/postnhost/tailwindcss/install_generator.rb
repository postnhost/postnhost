require "json"

module Postnhost
  module Generators
    module Tailwindcss
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        namespace "postnhost:tailwindcss:install"
        desc "Install host Tailwind pipeline for Postnhost view overrides."

        def create_stylesheet_directory
          empty_directory "app/assets/stylesheets/postnhost"
        end

        def create_tailwind_config
          path = Rails.root.join("postnhost.tailwind.config.js")
          return if path.exist?

          copy_file "tailwind.config.js", path
        end

        def create_host_stylesheet
          path = Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css")
          return if path.exist?

          copy_file "host.tailwind.css", path
        end

        def update_package_json
          path = Rails.root.join("package.json")
          return say_package_json_instructions unless path.exist?

          json_data = JSON.parse(File.read(path))
          json_data["scripts"] ||= {}
          json_data["devDependencies"] ||= {}

          json_data["scripts"]["postnhost:tailwindcss"] = tailwind_build_command
          json_data["scripts"]["postnhost:tailwindcss:watch"] = "#{tailwind_build_command} --watch"

          ensure_dependency(json_data, "tailwindcss", "^4.1.12")
          ensure_dependency(json_data, "@tailwindcss/cli", "^4.1.12")
          ensure_dependency(json_data, "@tailwindcss/typography", "^0.5.16")

          File.write(path, "#{JSON.pretty_generate(json_data)}\n")

          say "Updated package.json script:", :green
          say "  yarn postnhost:tailwindcss:watch"
        end

        def wire_procfile_dev
          path = Rails.root.join("Procfile.dev")
          entry = "postnhost_css: bundle exec rails postnhost:tailwindcss:watch"

          if path.exist?
            if File.read(path).include?("postnhost:tailwindcss:watch")
              say "Procfile.dev already includes Postnhost watcher.", :green
            else
              append_to_file path, "\n#{entry}\n"
              say "Added Postnhost watcher to Procfile.dev.", :green
            end
          else
            create_file "Procfile.dev", "#{entry}\n"
            say "Created Procfile.dev with Postnhost watcher.", :green
          end
        end

        def print_next_steps
          say ""
          say "Postnhost host-tailwind mode installed.", :green
          say "Next steps:"
          say "  1. Run bin/dev (Postnhost watcher is wired in Procfile.dev)."
          say "  2. Keep default layout tags; Postnhost auto-loads postnhost/host when config is present."
          say ""
        end

        private

        def tailwind_build_command
          "./node_modules/.bin/tailwindcss -i ./app/assets/stylesheets/postnhost/host.tailwind.css -o ./app/assets/builds/postnhost/host.css -c ./postnhost.tailwind.config.js --minify"
        end

        def ensure_dependency(json_data, package_name, version)
          return if json_data["dependencies"]&.key?(package_name) || json_data["devDependencies"].key?(package_name)

          json_data["devDependencies"][package_name] = version
        end

        def say_package_json_instructions
          say "package.json not found. Add these scripts manually:", :yellow
          say "  \"postnhost:tailwindcss\": \"#{tailwind_build_command}\""
          say "  \"postnhost:tailwindcss:watch\": \"#{tailwind_build_command} --watch\""
        end
      end
    end
  end
end

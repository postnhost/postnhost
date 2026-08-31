require "json"

module Postnhost
  module Generators
    module Tailwindcss
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        namespace "postnhost:tailwindcss:install"
        desc "Install host Tailwind support for PostnHost view overrides."

        def create_stylesheet_directory
          empty_directory "app/assets/stylesheets/postnhost"
        end

        def create_host_stylesheet
          path = Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css")
          return if path.exist?

          copy_file "host.tailwind.css", path
        end

        def update_package_json
          path = Rails.root.join("package.json")
          return say_package_json_instructions unless path.exist?

          @package_json_present = true

          json_data = JSON.parse(File.read(path))
          json_data["scripts"] ||= {}
          json_data["devDependencies"] ||= {}

          json_data["scripts"]["postnhost:tailwindcss"] = "bundle exec rails postnhost:tailwindcss:build"
          json_data["scripts"]["postnhost:tailwindcss:watch"] = "bundle exec rails postnhost:tailwindcss:watch"

          ensure_dependency(json_data, "tailwindcss", "^4.1.12")
          ensure_dependency(json_data, "@tailwindcss/cli", "^4.1.12")
          ensure_dependency(json_data, "@tailwindcss/typography", "^0.5.16")

          File.write(path, "#{JSON.pretty_generate(json_data)}\n")

          say "Updated package.json with PostnHost Tailwind scripts and dependencies.", :green
        end

        def wire_procfile_dev
          path = Rails.root.join("Procfile.dev")
          entry = "postnhost_css: bundle exec rails postnhost:tailwindcss:watch"

          if path.exist?
            if File.read(path).include?("postnhost:tailwindcss:watch")
              say "Procfile.dev already includes the PostnHost watcher.", :green
            else
              append_to_file path, "\n#{entry}\n"
              say "Added the PostnHost watcher to Procfile.dev.", :green
            end
          else
            create_file "Procfile.dev", "#{entry}\n"
            say "Created Procfile.dev with the PostnHost watcher.", :green
          end
        end

        def print_next_steps
          say ""
          say "PostnHost host Tailwind support installed.", :green
          say "Next steps:"
          step = 1

          if @package_json_present
            say "  #{step}. Install dependencies with the JavaScript package manager used by this app."
            step += 1
          end

          if Rails.root.join("bin/dev").exist?
            say "  #{step}. Run bin/dev; the PostnHost watcher is wired in Procfile.dev."
          else
            say "  #{step}. Run bin/rails postnhost:tailwindcss:watch alongside your Rails server."
          end

          say "  #{step + 1}. Use normal Tailwind classes in copied PostnHost views."
          say "  #{step + 2}. Keep the default layout tags; the combined build overrides postnhost/application automatically."
          say ""
        end

        private

        def ensure_dependency(json_data, package_name, version)
          return if json_data["dependencies"]&.key?(package_name) || json_data["devDependencies"].key?(package_name)

          json_data["devDependencies"][package_name] = version
        end

        def say_package_json_instructions
          say "package.json not found. Add a Tailwind CSS 4 compiler to the host Gemfile:", :yellow
          say '  gem "tailwindcss-ruby", "~> 4.0"'
          say "Then run bundle install."
        end
      end
    end
  end
end

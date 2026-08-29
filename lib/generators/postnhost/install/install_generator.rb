module Postnhost
  module Generators
    class InstallGenerator < Rails::Generators::Base
      DEFAULT_MOUNT_PATH = "/blog"

      source_root File.expand_path("templates", __dir__)

      desc "Creates Postnhost initializer and mounts the engine"

      def create_initializer
        template "postnhost.rb", "config/initializers/postnhost.rb"
      end

      def create_carrierwave_initializer
        return if File.exist?("config/initializers/carrierwave.rb")

        template "carrierwave.rb", "config/initializers/carrierwave.rb"
      end

      def mount_engine
        route "mount Postnhost::Engine, at: \"#{DEFAULT_MOUNT_PATH}\""
      end

      def show_post_install
        say ""
        say "=" * 60
        say "Postnhost has been installed!", :green
        say "=" * 60
        say ""
        say "Next steps:"
        say "  1. Run migrations:"
        say "     bin/rails postnhost:install:migrations"
        say "     bin/rails db:migrate"
        say ""
        say "  2. Open first-time setup in the browser:"
        say "     http://localhost:3000#{DEFAULT_MOUNT_PATH}/onboarding"
        say "     Or create a CMS user interactively: bin/rails g postnhost:user"
        say ""
        say "  3. Update config/initializers/postnhost.rb with your site settings."
        say ""
        say "  4. (Optional) Customize public views:"
        say "     rails g postnhost:views --views-scope=minimal"
        say "     # or"
        say "     rails g postnhost:views --views-scope=full"
        say ""
        say "  5. (Optional) Enable host Tailwind pipeline for custom Postnhost classes:"
        say "     rails g postnhost:tailwindcss:install"
        say "     bundle exec rails postnhost:tailwindcss:watch"
        say ""
        say "  6. (Optional) Add a new public locale (copy English strings into your app):"
        say "     rails g postnhost:locale sv"
        say ""
      end
    end
  end
end

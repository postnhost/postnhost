module Postnhost
  module Generators
    class InstallGenerator < Rails::Generators::Base
      DEFAULT_MOUNT_PATH = "/blog"

      source_root File.expand_path("templates", __dir__)

      desc "Creates the PostnHost initializer and mounts the engine"

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
        say "PostnHost has been installed!", :green
        say "=" * 60
        say ""
        say "Next steps:"
        say "  1. Run migrations:"
        say "     bin/rails postnhost:install:migrations"
        say "     bin/rails db:migrate"
        say ""
        say "  2. Open first-time setup in your app:"
        say "     #{DEFAULT_MOUNT_PATH}/onboarding"
        say "     Or create a CMS user interactively: bin/rails g postnhost:user"
        say ""
        say "  3. Review config/initializers/postnhost.rb for optional defaults, production uploads, and AI translations."
        say ""
        say "  4. (Optional) Customize public views:"
        say "     bin/rails g postnhost:views --views-scope=minimal"
        say "     or"
        say "     bin/rails g postnhost:views --views-scope=full"
        say ""
        say "  5. (Optional) Enable host Tailwind support for custom PostnHost classes:"
        say "     bin/rails g postnhost:tailwindcss:install"
        say ""
        say "  6. (Optional) Add a new public locale (copy English strings into your app):"
        say "     bin/rails g postnhost:locale sv"
        say ""
      end
    end
  end
end

require "json"

# rubocop:disable-next Metrics/BlockLength
namespace :postnhost do
  namespace :tailwindcss do
    def postnhost_tailwind_enabled?
      Rails.root.join("postnhost.tailwind.config.js").exist? &&
        Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css").exist?
    end

    def tailwindcss_rails_compile_command(watch: false)
      return unless Gem.loaded_specs.key?("tailwindcss-rails") || Gem.loaded_specs.key?("tailwindcss-ruby")

      begin
        require "tailwindcss/ruby"
      rescue LoadError
        return
      end

      executable = Tailwindcss::Ruby.executable
      return if executable.blank?

      command = [
        executable,
        "-i", Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css").to_s,
        "-o", Rails.root.join("app/assets/builds/postnhost/host.css").to_s,
        "-c", Rails.root.join("postnhost.tailwind.config.js").to_s,
        "--minify"
      ]
      command << "-w" if watch
      command
    end

    def package_json_scripts
      path = Rails.root.join("package.json")
      return {} unless path.exist?

      JSON.parse(File.read(path)).fetch("scripts", {})
    rescue JSON::ParserError
      {}
    end

    def npm_compile_command(watch: false)
      script = watch ? "postnhost:tailwindcss:watch" : "postnhost:tailwindcss"
      return unless package_json_scripts.key?(script)

      ["yarn", script]
    end

    def postnhost_tailwind_command(watch: false)
      tailwindcss_rails_compile_command(watch:) || npm_compile_command(watch:)
    end

    def print_missing_tailwind_runner_message
      puts <<~MSG
        [postnhost] No Tailwind runner found for host mode.
        - Option 1: add the `tailwindcss-rails` gem to your host app.
        - Option 2: add package.json script `postnhost:tailwindcss:watch` (and `postnhost:tailwindcss` for build).
      MSG
    end

    desc "Build host Tailwind CSS for Postnhost overrides"
    task build: :environment do
      unless postnhost_tailwind_enabled?
        puts "[postnhost] Skipping host Tailwind build (missing postnhost.tailwind.config.js or app/assets/stylesheets/postnhost/host.tailwind.css)"
        next
      end

      command = postnhost_tailwind_command
      unless command
        print_missing_tailwind_runner_message
        next
      end

      system(*command, exception: true)
    end

    desc "Watch host Tailwind CSS for Postnhost overrides"
    task watch: :environment do
      unless postnhost_tailwind_enabled?
        puts "[postnhost] Missing host Tailwind files. Run: rails g postnhost:tailwindcss:install"
        next
      end

      command = postnhost_tailwind_command(watch: true)
      unless command
        print_missing_tailwind_runner_message
        next
      end

      system(*command, exception: true)
    end
  end
end

Rake::Task["assets:precompile"].enhance(["postnhost:tailwindcss:build"]) if Rake::Task.task_defined?("assets:precompile")

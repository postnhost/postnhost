require "fileutils"

require "postnhost/css_build"
require "postnhost/tailwind_compiler"
require "postnhost/tailwind_input"

# rubocop:disable-next Metrics/BlockLength
namespace :postnhost do
  namespace :tailwindcss do
    def postnhost_tailwind_enabled?
      Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css").exist?
    end

    def host_tailwind_paths
      {
        input: Rails.root.join("tmp/postnhost/host.tailwind.css"),
        unscoped: Rails.root.join("app/assets/builds/postnhost/application.unscoped.css"),
        output: Rails.root.join("app/assets/builds/postnhost/application.css")
      }
    end

    def write_host_tailwind_input(path)
      engine_source = Postnhost::Engine.root.join("app/assets/stylesheets/application.tailwind.css")
      host_source = Rails.root.join("app/assets/stylesheets/postnhost/host.tailwind.css")

      FileUtils.mkdir_p(path.dirname)
      path.write(Postnhost::TailwindInput.build(engine_source:, host_source:))
    end

    def build_host_tailwind(watch: false)
      paths = host_tailwind_paths
      write_host_tailwind_input(paths[:input])
      command = Postnhost::TailwindCompiler.new(root: Rails.root).command(
        input_path: paths[:input],
        output_path: paths[:unscoped],
        watch:
      )

      Postnhost::CssBuild.run(
        command:,
        unscoped_path: paths[:unscoped],
        output_path: paths[:output],
        watch:
      )
    ensure
      FileUtils.rm_f(paths&.dig(:input))
    end

    desc "Build host Tailwind CSS for PostnHost overrides"
    task build: :environment do
      unless postnhost_tailwind_enabled?
        puts "[postnhost] Skipping host Tailwind build (missing app/assets/stylesheets/postnhost/host.tailwind.css)"
        next
      end

      build_host_tailwind
    end

    desc "Watch host Tailwind CSS for PostnHost overrides"
    task watch: :environment do
      unless postnhost_tailwind_enabled?
        puts "[postnhost] Missing host Tailwind files. Run: bin/rails g postnhost:tailwindcss:install"
        next
      end

      build_host_tailwind(watch: true)
    end
  end
end

Rake::Task["assets:precompile"].enhance(["postnhost:tailwindcss:build"]) if Rake::Task.task_defined?("assets:precompile")

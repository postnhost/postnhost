require "bundler/setup"
require "fileutils"

require "bundler/gem_tasks"
require_relative "lib/postnhost/css_build"

css_build = lambda do |watch:|
  root = __dir__
  unscoped_path = File.join(root, "app/assets/builds/postnhost/application.unscoped.css")
  output_path = File.join(root, "app/assets/builds/postnhost/application.css")
  command = [
    File.join(root, "node_modules/.bin/tailwindcss"),
    "-i", File.join(root, "app/assets/stylesheets/application.tailwind.css"),
    "-o", unscoped_path,
    "--minify"
  ]
  command << "--watch" if watch

  Postnhost::CssBuild.run(command:, unscoped_path:, output_path:, watch:)
end

namespace :css do
  desc "Build the engine stylesheet"
  task build: :environment do
    css_build.call(watch: false)
  end

  desc "Build the engine stylesheet and watch for changes"
  task watch: :environment do
    css_build.call(watch: true)
  end
end

# Load dummy app so the Rails `environment` task exists (required by prepare_test_db).
require_relative "spec/dummy/config/application"
Rails.application.load_tasks

desc "Prepare dummy app test database"
task prepare_test_db: :environment do
  dummy_dir = File.expand_path("spec/dummy", __dir__)
  engine_migrations_dir = File.expand_path("db/migrate", __dir__)
  dummy_migrations_dir = File.join(dummy_dir, "db", "migrate")
  dummy_test_db = File.join(dummy_dir, "storage", "test.sqlite3")
  dummy_schema = File.join(dummy_dir, "db", "schema.rb")

  FileUtils.mkdir_p(dummy_migrations_dir)
  FileUtils.rm_f(Dir[File.join(dummy_migrations_dir, "*.rb")])
  Dir[File.join(engine_migrations_dir, "*.rb")].each do |migration_file|
    FileUtils.cp(migration_file, dummy_migrations_dir)
  end
  FileUtils.rm_f(dummy_test_db)
  FileUtils.rm_f(dummy_schema)

  system(
    { "RAILS_ENV" => "test" },
    "cd #{dummy_dir} && bundle exec rails db:create db:migrate",
    out: $stdout,
    err: $stderr
  ) ||
    raise("Failed to prepare test database")
end

begin
  require "rspec/core/rake_task"

  desc "Run engine specs"
  RSpec::Core::RakeTask.new(:spec)
  task spec: :prepare_test_db
  task default: :spec
rescue LoadError
  # rspec-rails is not available in minimal environments.
end

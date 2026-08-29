require "rails_helper"
require "rails/generators"
require "generators/postnhost/install/install_generator"
require "generators/postnhost/locale/locale_generator"
require "generators/postnhost/static_pages/static_pages_generator"
require "generators/postnhost/tailwindcss/install_generator"
require "generators/postnhost/views/views_generator"

# This integration spec intentionally exercises the generator suite together.
# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Postnhost::Generators do
  let(:destination_root) { Pathname.new(Dir.mktmpdir("postnhost-generator-spec")) }

  around do |example|
    example.run
  ensure
    FileUtils.remove_entry(destination_root) if destination_root.exist?
  end

  def generator_for(generator_class, arguments = [], options = {})
    generator_class.new(arguments, options, destination_root: destination_root.to_s)
  end

  describe Postnhost::Generators::InstallGenerator do
    it "installs initializers and mounts the engine idempotently" do
      FileUtils.mkdir_p(destination_root.join("config"))
      File.write(destination_root.join("config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      generator = generator_for(described_class)

      generator.create_initializer
      generator.create_carrierwave_initializer
      generator.mount_engine
      generator.create_carrierwave_initializer
      generator.show_post_install

      expect(destination_root.join("config/initializers/postnhost.rb")).to exist
      expect(destination_root.join("config/initializers/carrierwave.rb")).to exist
      expect(destination_root.join("config/routes.rb").read).to include('mount Postnhost::Engine, at: "/blog"')
    end
  end

  describe Postnhost::Generators::LocaleGenerator do
    it "copies a locale once and rejects unsafe locale names" do
      generator = generator_for(described_class, ["sv"])

      generator.copy_postnhost_locale
      first_contents = destination_root.join("config/locales/sv.yml").read
      generator.copy_postnhost_locale

      expect(YAML.safe_load(first_contents)).to have_key("sv")
      expect(destination_root.join("config/locales/sv.yml").read).to eq(first_contents)
      expect do
        generator_for(described_class, ["../unsafe"]).copy_postnhost_locale
      end.to raise_error(Thor::Error, /Invalid locale/)
    end
  end

  describe Postnhost::Generators::StaticPagesGenerator do
    it "creates valid slugs and skips invalid input" do
      generator_for(described_class, ["terms", "bad slug"]).create_static_pages

      expect(destination_root.join("app/views/postnhost/static_pages/terms.html.erb")).to exist
      expect(destination_root.join("app/views/postnhost/static_pages/bad slug.html.erb")).not_to exist
    end

    it "does nothing when no slugs are supplied" do
      generator_for(described_class).create_static_pages

      expect(destination_root.join("app/views/postnhost/static_pages")).not_to exist
    end
  end

  describe Postnhost::Generators::Tailwindcss::InstallGenerator do
    it "installs and updates the host Tailwind pipeline idempotently" do
      allow(Rails).to receive(:root).and_return(destination_root)
      File.write(destination_root.join("package.json"), "{}\n")
      File.write(destination_root.join("Procfile.dev"), "web: bin/rails server\n")
      generator = generator_for(described_class)

      generator.create_stylesheet_directory
      generator.create_tailwind_config
      generator.create_host_stylesheet
      generator.update_package_json
      generator.wire_procfile_dev
      generator.create_tailwind_config
      generator.create_host_stylesheet
      generator.wire_procfile_dev
      generator.print_next_steps

      package_json = JSON.parse(destination_root.join("package.json").read)
      expect(package_json.dig("scripts", "postnhost:tailwindcss")).to include("tailwindcss")
      expect(package_json.dig("devDependencies", "@tailwindcss/typography")).to eq("^0.5.16")
      expect(destination_root.join("Procfile.dev").read.scan("postnhost_css:").size).to eq(1)
    end

    it "prints manual instructions when package.json is absent" do
      allow(Rails).to receive(:root).and_return(destination_root)

      generator_for(described_class).update_package_json

      expect(destination_root.join("package.json")).not_to exist
    end
  end

  describe Postnhost::Generators::ViewsGenerator do
    it "copies minimal public views" do
      allow(Rails).to receive(:root).and_return(destination_root)

      generator_for(described_class, [], views_scope: "minimal").copy_views

      expect(destination_root.join("app/views/postnhost/public/templates/default/articles/index.html.erb")).to exist
      expect(destination_root.join("app/views/layouts/postnhost/_footer.html.erb")).to exist
      expect(destination_root.join("app/views/postnhost/shared/_structured_data.html.erb")).not_to exist
    end

    it "copies full public views and shared SEO partials" do
      allow(Rails).to receive(:root).and_return(destination_root)

      generator_for(described_class, [], views_scope: "full").copy_views

      expect(destination_root.join("app/views/postnhost/public/templates/swiss-editorial/articles/index.html.erb")).to exist
      expect(destination_root.join("app/views/postnhost/shared/_structured_data.html.erb")).to exist
    end
  end
end

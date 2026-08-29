module Postnhost
  class Engine < ::Rails::Engine
    isolate_namespace Postnhost

    # Initialize configuration before other initializers
    initializer "postnhost.configuration", before: :load_config_initializers do
      Postnhost.configure
    end

    initializer "postnhost.yaml_column_permitted_classes" do |app|
      permitted_classes = app.config.active_record.yaml_column_permitted_classes ||= []
      [
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        Time,
        Date,
        Symbol
      ].each do |klass|
        permitted_classes << klass unless permitted_classes.include?(klass)
      end
    end

    initializer "postnhost.i18n_patch" do
      I18n.backend.singleton_class.prepend(Postnhost::Settings::I18nPatch) unless I18n.backend.singleton_class.ancestors.include?(Postnhost::Settings::I18nPatch)
    end

    # Asset pipeline configuration (Sprockets + Propshaft compatible)
    initializer "postnhost.assets" do |app|
      if app.config.respond_to?(:assets)
        # For Propshaft: add builds directory so postnhost/application.css is found
        # The path structure is: builds/postnhost/application.css
        # When requesting "postnhost/application", Propshaft finds it in builds/
        app.config.assets.paths << Engine.root.join("app", "assets", "builds").to_s
        app.config.assets.paths << Engine.root.join("app", "assets", "images").to_s

        # For Sprockets: programmatically add all assets to precompile
        if defined?(::Sprockets)
          asset_paths = [
            %w[app assets builds postnhost],
            %w[app assets images postnhost]
          ]

          paths_to_precompile = asset_paths.flat_map do |path|
            Dir[Engine.root.join(*path, "**", "*")].filter_map do |file|
              next unless File.file?(file)

              Pathname.new(file).relative_path_from(Engine.root.join(*path)).to_s
            end
          end

          app.config.assets.precompile += paths_to_precompile
          app.config.assets.precompile += %w[postnhost_manifest.js]
        end
      end
    end
  end
end

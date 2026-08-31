require "json"
require "pathname"
require "rubygems/version"

module Postnhost
  class TailwindCompiler
    REQUIRED_MAJOR = 4

    class MissingCompiler < StandardError; end
    class IncompatibleVersion < StandardError; end

    def initialize(root:, loaded_specs: Gem.loaded_specs)
      @root = Pathname.new(root)
      @loaded_specs = loaded_specs
    end

    def command(input_path:, output_path:, watch: false)
      command = npm_command(input_path:, output_path:) || ruby_command(input_path:, output_path:)
      raise MissingCompiler, missing_compiler_message unless command

      command << "--watch" if watch
      command
    end

    private

    attr_reader :root, :loaded_specs

    def ruby_command(input_path:, output_path:)
      spec = loaded_specs["tailwindcss-ruby"]
      return unless spec

      validate_version!(spec.version, "tailwindcss-ruby")
      require "tailwindcss/ruby"
      executable = Tailwindcss::Ruby.executable
      return if executable.to_s.empty?

      [executable, "-i", input_path.to_s, "-o", output_path.to_s, "--minify"]
    end

    def npm_command(input_path:, output_path:)
      executable = root.join("node_modules/.bin/tailwindcss")
      return unless executable.file?

      validate_package_version!("tailwindcss")
      validate_package_version!("@tailwindcss/cli")

      [executable.to_s, "-i", input_path.to_s, "-o", output_path.to_s, "--minify"]
    end

    def validate_package_version!(package_name)
      package_path = root.join("node_modules", package_name, "package.json")
      raise MissingCompiler, "[postnhost] Missing #{package_name}. Install Tailwind CSS 4 and @tailwindcss/cli 4." unless package_path.file?

      version = JSON.parse(package_path.read).fetch("version")
      validate_version!(version, package_name)
    rescue JSON::ParserError, KeyError
      raise MissingCompiler, "[postnhost] Cannot read the installed #{package_name} version."
    end

    def validate_version!(version, source)
      return if Gem::Version.new(version.to_s).segments.first == REQUIRED_MAJOR

      raise IncompatibleVersion,
            "[postnhost] Host CSS requires Tailwind CSS 4; found #{source} #{version}."
    end

    def missing_compiler_message
      <<~MESSAGE.strip
        [postnhost] No Tailwind CSS 4 compiler found for host customization.
        Add tailwindcss-ruby 4, or install tailwindcss 4 and @tailwindcss/cli 4.
      MESSAGE
    end
  end
end

require "rails_helper"
require "postnhost/tailwind_compiler"

RSpec.describe Postnhost::TailwindCompiler do
  def write_package(root, name, version)
    path = root.join("node_modules", name, "package.json")
    FileUtils.mkdir_p(path.dirname)
    path.write(JSON.generate(name:, version:))
  end

  it "builds a command for an npm Tailwind CSS 4 compiler" do
    Dir.mktmpdir("postnhost-tailwind-compiler") do |directory|
      root = Pathname.new(directory)
      executable = root.join("node_modules/.bin/tailwindcss")
      FileUtils.mkdir_p(executable.dirname)
      executable.write("")
      write_package(root, "tailwindcss", "4.3.3")
      write_package(root, "@tailwindcss/cli", "4.3.3")

      command = described_class.new(root:, loaded_specs: {}).command(
        input_path: root.join("input.css"),
        output_path: root.join("output.css"),
        watch: true
      )

      expect(command).to eq([
                              executable.to_s,
                              "-i", root.join("input.css").to_s,
                              "-o", root.join("output.css").to_s,
                              "--minify",
                              "--watch"
                            ])
    end
  end

  it "rejects an existing Tailwind CSS 3 compiler" do
    Dir.mktmpdir("postnhost-tailwind-compiler") do |directory|
      root = Pathname.new(directory)
      executable = root.join("node_modules/.bin/tailwindcss")
      FileUtils.mkdir_p(executable.dirname)
      executable.write("")
      write_package(root, "tailwindcss", "3.4.17")
      write_package(root, "@tailwindcss/cli", "4.3.3")

      expect do
        described_class.new(root:, loaded_specs: {}).command(
          input_path: root.join("input.css"),
          output_path: root.join("output.css")
        )
      end.to raise_error(described_class::IncompatibleVersion, /requires Tailwind CSS 4/)
    end
  end

  it "prefers a valid npm compiler over an incompatible Ruby compiler" do
    Dir.mktmpdir("postnhost-tailwind-compiler") do |directory|
      root = Pathname.new(directory)
      executable = root.join("node_modules/.bin/tailwindcss")
      FileUtils.mkdir_p(executable.dirname)
      executable.write("")
      write_package(root, "tailwindcss", "4.3.3")
      write_package(root, "@tailwindcss/cli", "4.3.3")
      ruby_spec = Struct.new(:version).new(Gem::Version.new("3.4.17"))

      command = described_class.new(root:, loaded_specs: { "tailwindcss-ruby" => ruby_spec }).command(
        input_path: root.join("input.css"),
        output_path: root.join("output.css")
      )

      expect(command.first).to eq(executable.to_s)
    end
  end

  it "fails when no compiler is installed" do
    Dir.mktmpdir("postnhost-tailwind-compiler") do |directory|
      expect do
        described_class.new(root: directory, loaded_specs: {}).command(
          input_path: "input.css",
          output_path: "output.css"
        )
      end.to raise_error(described_class::MissingCompiler, /No Tailwind CSS 4 compiler/)
    end
  end
end

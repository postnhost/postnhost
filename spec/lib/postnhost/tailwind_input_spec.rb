require "rails_helper"
require "postnhost/tailwind_input"

RSpec.describe Postnhost::TailwindInput do
  it "combines engine and host sources with absolute paths" do
    Dir.mktmpdir("postnhost-tailwind-input") do |directory|
      root = Pathname.new(directory)
      engine_source = root.join("engine/application.tailwind.css")
      host_source = root.join("host/host.tailwind.css")
      FileUtils.mkdir_p([engine_source.dirname, host_source.dirname])
      engine_source.write(%(@import "tailwindcss" source(none);\n@source "../views/**/*.erb";\n))
      host_source.write(%(@source "../overrides/**/*.erb";\n))

      input = described_class.build(engine_source:, host_source:)

      expect(input).to include(%(@source "#{root.join('views/**/*.erb')}";))
      expect(input).to include(%(@source "#{root.join('overrides/**/*.erb')}";))
      expect(input).to include('@import "tailwindcss" source(none);')
    end
  end
end

require "pathname"

module Postnhost
  class TailwindInput
    SOURCE_PATTERN = /@source\s+"([^"]+)";/

    class << self
      def build(engine_source:, host_source:)
        [
          expand_sources(engine_source),
          expand_sources(host_source)
        ].join("\n\n")
      end

      private

      def expand_sources(path)
        source_path = Pathname.new(path)

        source_path.read.gsub(SOURCE_PATTERN) do
          relative_source = Regexp.last_match(1)
          absolute_source = source_path.dirname.join(relative_source).expand_path
          %(@source "#{css_path(absolute_source)}";)
        end
      end

      def css_path(path)
        Pathname.new(path).expand_path.to_s.tr("\\", "/").gsub('"', '\\"')
      end
    end
  end
end

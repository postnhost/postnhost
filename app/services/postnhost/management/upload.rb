require "base64"
require "stringio"

module Postnhost
  module Management
    module Upload
      def self.open(payload)
        filename = payload.fetch("filename")
        raise ArgumentError, "Invalid filename" if filename.blank? || filename != File.basename(filename) || filename.include?("\\")

        file = StringIO.new(Base64.strict_decode64(payload.fetch("base64")))
        file.define_singleton_method(:original_filename) { filename }
        file.define_singleton_method(:content_type) { payload.fetch("content_type") }
        file
      end
    end
  end
end

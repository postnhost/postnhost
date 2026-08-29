module Postnhost
  module Publishing
    class Error < StandardError
      attr_reader :messages

      def initialize(messages)
        @messages = Array(messages)
        super(@messages.join(", "))
      end
    end
  end
end

module Postnhost
  module Constraints
    class PublicLocaleConstraint
      def self.matches?(request)
        Postnhost::PublicRequestContext.for(request).localized_language?
      end
    end
  end
end

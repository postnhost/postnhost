module Postnhost
  module Constraints
    class PublicRouteConstraint
      def initialize(kind:, parameter:)
        @kind = kind
        @parameter = parameter
      end

      def matches?(request)
        slug = request.params.fetch(parameter)
        Postnhost::PublicRequestContext.for(request).resolve_kind(kind, slug).present?
      end

      private

      attr_reader :kind, :parameter
    end
  end
end

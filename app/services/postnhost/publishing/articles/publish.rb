module Postnhost
  module Publishing
    class Articles::Publish < BaseService
      def initialize(article:)
        @article = article
      end

      def call
        snapshot = Revision.hold do
          article.lock!
          Articles::SnapshotWriter.new(article:).call
        end
        success(snapshot, status: :ok)
      rescue Error => e
        failure(e.messages)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        failure(e.message)
      end

      private

      attr_reader :article
    end
  end
end

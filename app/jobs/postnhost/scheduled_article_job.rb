module Postnhost
  class ScheduledArticleJob < ApplicationJob
    queue_as :publishing

    queue_with_priority 1

    retry_on StandardError, attempts: 3

    def perform(article_id)
      Postnhost::Publishing::Articles::PublishScheduled.call(article_id:, job_id:)
    end
  end
end

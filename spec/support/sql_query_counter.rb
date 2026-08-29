module SqlQueryCounter
  IGNORED_QUERY_NAMES = %w[SCHEMA TRANSACTION].freeze
  TRANSACTION_SQL = /\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/

  def capture_sql_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*arguments|
      event = ActiveSupport::Notifications::Event.new(*arguments)
      payload = event.payload
      next if payload[:cached] || IGNORED_QUERY_NAMES.include?(payload[:name])

      sql = payload.fetch(:sql).squish
      queries << sql unless sql.match?(TRANSACTION_SQL)
    end

    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

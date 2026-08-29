require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("dummy/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "capybara/rspec"
require "database_cleaner/active_record"
require "webmock/rspec"
require "factory_bot_rails"

Dir[Postnhost::Engine.root.join("spec/support/**/*.rb")].each { |file| require file }

# Avoid Psych safe-load class restrictions in Ruby 3.4 when reifying PaperTrail versions.
PaperTrail.serializer = PaperTrail::Serializers::JSON

FactoryBot.definition_file_paths = [Postnhost::Engine.root.join("spec/factories").to_s]
FactoryBot.find_definitions

WebMock.disable_net_connect!(allow_localhost: true)

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort(e.to_s.strip)
end

RSpec.configure do |config|
  config.fixture_paths = [Postnhost::Engine.root.join("spec/fixtures")]
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper
  config.include AuthenticationHelpers, type: :request
  config.include SqlQueryCounter, type: :request
  config.include SystemTestHelpers, type: :system

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around do |example|
    DatabaseCleaner.strategy = example.metadata[:type] == :system ? :truncation : :transaction
    I18n.with_locale(I18n.default_locale) do
      DatabaseCleaner.cleaning do
        example.run
      end
    end
  end

  config.before(:each, type: :system) do
    # Headed Chrome requires a display; CI must always use headless.
    use_headed = ENV["SYSTEM_TESTS_BROWSER"].present? && ENV["CI"].blank?
    driver = use_headed ? :selenium_chrome : :selenium_chrome_headless
    driven_by driver, screen_size: [1400, 900]
  end
end

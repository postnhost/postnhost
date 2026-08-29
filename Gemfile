source "https://rubygems.org"

# Specify your gem's dependencies in postnhost.gemspec.
gemspec

gem "puma"

gem "propshaft"
gem "sqlite3"

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

group :development, :test do
  gem "rspec-rails"
end

group :development do
  gem "appraisal", require: false
  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "faker"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock"
end

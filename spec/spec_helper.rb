if ENV["COVERAGE"] == "1"
  require "simplecov"

  SimpleCov.start do
    skip "/spec/"
    skip "/lib/generators/postnhost/install/templates/"
    skip "/lib/postnhost/version.rb"

    cover "{app,lib}/**/*.rb"

    group "Controllers", "app/controllers"
    group "Helpers", "app/helpers"
    group "Jobs", "app/jobs"
    group "Models", "app/models"
    group "Services", "app/services"
    group "Uploaders", "app/uploaders"
    group "Generators", "lib/generators"
    group "Library", "lib/postnhost"

    enable_coverage :branch
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

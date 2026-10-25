# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "webmock/rspec"
# Add additional requires below this line. Rails is not loaded until this point!

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  warn e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  # QuickBooks is live in every environment (see config/initializers/quickbooks.rb), so specs must never reach it.
  WebMock.disable_net_connect!(allow_localhost: true)

  # Intuit's discovery documents are fetched at runtime; serve them from a stub and start each example uncached.
  config.before do
    IntuitDiscovery.reset!
    IntuitDiscovery::DOCUMENTS.each_value do |url|
      stub_request(:get, url).to_return(body: IntuitDiscovery::FALLBACK.to_json)
    end
  end

  # IntuitAccount.instance memoizes at class level, which would leak a rolled-back record between examples.
  config.before { IntuitAccount.instance_variable_set(:@instance, nil) }
end

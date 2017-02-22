require 'coveralls'
Coveralls.wear!

require 'webmock/rspec'
require 'support/request_helpers'

RSpec.configure do |config|
  config.order = 'random'
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include Requests::JsonHelpers, type: :request
end

# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support
Cucumber::Rails.use_transactional_fixtures
Cucumber::Rails.bypass_rescue # Comment out this line if you want Rails own error handling 
                              # (e.g. rescue_action_in_public / rescue_responses / rescue_from)

require 'webrat'
require 'test/forgeries'

Webrat.configure do |config|
  config.mode = :rails
end

require 'cucumber/rails/rspec'
require 'webrat/core/matchers'

# require 'spec/mocks/framework'
# require 'spec/mocks/extensions'
# 
# World(Spec::Mocks::ExampleMethods)
# 
# Before do
#   $rspec_stubs ||= Spec::Mocks::Space.new
# end
# 
# After do
#   $rspec_stubs.reset_all
# end

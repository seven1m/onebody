# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.gem 'faker'
config.gem 'thoughtbot-shoulda', :source => 'http://gems.github.com', :lib => 'shoulda'

# these have to be loaded a bit earlier than usual
# don't really know why
require Rails.root + 'config/initializers/paths'
require Rails.root + 'config/initializers/photos'
require Rails.root + 'config/initializers/email'

config.action_controller.session = {
  :session_key => "_onebody_session",
  :secret      => "not so secret - this is only here for the test environment"
} 
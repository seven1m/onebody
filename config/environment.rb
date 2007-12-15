# ENV['RAILS_ENV'] ||= 'production'

RAILS_GEM_VERSION = '2.0.1' unless defined? RAILS_GEM_VERSION

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.action_controller.session_store = :active_record_store
end
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.action_controller.session_store = :active_record_store
  config.log_path = File.join(File.dirname(__FILE__), "../log/#{RAILS_ENV}.log")
  config.database_configuration_file = File.expand_path(File.join(File.dirname(__FILE__), 'database.yml'))
end

ActionController::Base.perform_caching = false

PHONE_HOME_FOR_VERSION_INFO = true unless defined? PHONE_HOME_FOR_VERSION_INFO
DB_PHOTO_PATH = File.join(RAILS_ROOT, 'db/photos') unless defined? DB_PHOTO_PATH
DB_PUBLICATIONS_PATH = File.join(RAILS_ROOT, 'db/publications') unless defined? DB_PUBLICATIONS_PATH
DB_TASKS_PATH = File.join(RAILS_ROOT, 'db/tasks') unless defined? DB_TASKS_PATH
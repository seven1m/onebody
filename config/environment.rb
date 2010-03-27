RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION
require File.join(File.dirname(__FILE__), 'boot')

unless File.exist?(config_filename = "#{Rails.root}/config/database.yml")
  puts config_filename
  require 'fileutils'
  FileUtils.cp("#{config_filename}.example", config_filename)
end

Rails::Initializer.run do |config|
  config.action_controller.session_store = :active_record_store
  config.action_controller.cache_store = :file_store, "#{Rails.root}/cache"
  config.log_path = File.join(File.dirname(__FILE__), "../log/#{RAILS_ENV}.log")
  config.database_configuration_file = File.expand_path(File.join(File.dirname(__FILE__), 'database.yml'))
  config.load_paths << "#{Rails.root}/app/sweepers"
  config.plugin_paths << "#{Rails.root}/plugins"
  config.time_zone = 'UTC'
  config.i18n.default_locale = File.exist?("#{RAILS_ROOT}/config/locale") ? File.read("#{RAILS_ROOT}/config/locale").strip.to_sym : :en
  config.i18n.load_path << Dir["#{RAILS_ROOT}/plugins/**/config/locales/*.{rb,yml}"]
  # dependencies 
  config.gem 'transaction-simple',     :version => '~> 1.4.0', :lib => 'transaction/simple'
  config.gem 'color',                  :version => '~> 1.4.0'
  config.gem 'pdf-writer',             :version => '~> 1.1.8', :lib => 'pdf/writer'
  config.gem 'liquid',                 :version => '~> 2.0.0'
  config.gem 'highline',               :version => '~> 1.5.0'
  config.gem 'mini_magick',            :version => '>= 1.2.5'
  config.gem 'campaign_monitor_party', :version => '>= 0.2.1'
  config.gem 'whenever',               :version => '~> 0.4.0'
  config.gem 'nokogiri',               :version => '~> 1.4.0'
  config.gem 'builder',                :version => '>= 2.1.2'
  config.gem 'feedzirra',              :version => '>= 0.0.20'
  config.gem 'mongo',                  :version => '>= 0.18'
  config.gem 'fastercsv',              :version => '~> 1.5.0'
end

(Setting.update_all if Setting.table_exists?) rescue nil

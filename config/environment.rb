RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION
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
  # dependencies 
  config.gem 'tobi-liquid',                     :source => 'http://gems.github.com', :lib => 'liquid'
  config.gem 'color'
  config.gem 'transaction-simple',              :lib => 'transaction/simple'
  config.gem 'metaskills-pdf-writer',           :source => 'http://gems.github.com', :lib => 'pdf/writer'
  config.gem 'highline'
  config.gem 'mini_magick'
  config.gem 'twitter'
  config.gem 'xmpp4r'
  config.gem 'mislav-will_paginate',            :source => 'http://gems.github.com', :lib => 'will_paginate', :version => '~> 2.3.0'
  config.gem 'seven1m-acts_as_scoped_globally', :source => 'http://gems.github.com', :lib => 'acts_as_scoped_globally'
  config.gem 'seven1m-has_one_photo',           :source => 'http://gems.github.com', :lib => 'has_one_photo'
  config.gem 'seven1m-has_one_file',            :source => 'http://gems.github.com', :lib => 'has_one_file'
  config.gem 'seven1m-campaign_monitor',        :source => 'http://gems.github.com', :lib => 'campaign_monitor'
  config.gem 'chronic'
  config.gem 'javan-whenever',                  :source => 'http://gems.github.com', :lib => 'whenever'
  config.gem 'nokogiri'
  config.gem 'builder'
  config.gem 'pauldix-feedzirra',               :source => 'http://gems.github.com', :lib => 'feedzirra'
  # to install with your gem command (rake gems:install uses just plain 'gem' by default -- you might need to use gem19 or something else):
  # [gemcommand] install highline mini_magick twitter xmpp4r chronic nokogiri builder color transaction-simple
  # [gemcommand] install -s http://gems.github.com tobi-liquid metaskills-pdf-writer mislav-will_paginate seven1m-acts_as_scoped_globally seven1m-has_one_photo seven1m-has_one_file seven1m-campaign_monitor javan-whenever pauldix-feedzirra

  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  #config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :pt
end

PHONE_HOME_FOR_VERSION_INFO = true unless defined? PHONE_HOME_FOR_VERSION_INFO

(Setting.update_all if Setting.table_exists?) rescue nil

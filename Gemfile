require 'erb'
require 'yaml'

source 'http://rubygems.org'

gem 'rails', '~> 4.2.0'

# BEGIN database selection
# borrowed heavily from https://github.com/redmine/redmine/blob/master/Gemfile
database_file = File.expand_path('../config/database.yml', __FILE__)
if File.exist?(database_file)
  database_config = YAML::load(ERB.new(File.read(database_file)).result)
  adapters = database_config.values.map {|c| c['adapter']}.compact.uniq
  if adapters.any?
    adapters.each do |adapter|
      case adapter
      when 'mysql2'
        gem 'mysql2', '~> 0.3.17'
      when 'postgresql'
        gem 'pg', '~> 0.18.1'
      else
        warn("Unknown database adapter '#{adapter}' found in config/database.yml")
      end
    end
  else
    warn('No adapter found in config/database.yml, please configure it first')
  end
else
  warn('Please configure your config/database.yml first')
end
# END database selection

gem 'rails_autolink', '~> 1.1.6'
gem 'jquery-rails', '~> 4.0.3'
gem 'will_paginate', '~> 3.0.7'
gem 'highline', '~> 1.6.21'
gem 'whenever', '~> 0.9.4'
gem 'nokogiri', '~> 1.6.6.2'
gem 'builder', '~> 3.2.2'
gem 'loofah', '~> 2.0.1'
gem 'feedjira', '~> 1.6.0'
gem 'rubyzip', '~> 1.1.6'
gem 'zip-zip', '~> 0.3'
gem 'sanitize', '~> 3.1.0'
gem 'haml', '~> 4.0.6'
gem 'httparty', '~> 0.13.3'
gem 'draper', '~> 1.4.0'
gem 'paperclip', '~> 4.2.1'
gem 'acts_as_taggable_on_steroids', github: 'seven1m/acts_as_taggable_on_steroids', ref: 'cffba03'
gem 'acts_as_list', '~> 0.6.0'
gem 'pdf-writer', github: 'Hermanverschooten/pdf-writer', require: 'pdf/writer', ref: 'f57c298'
gem 'authority', '~> 3.0.0'
gem 'load_and_authorize_resource', github: 'seven1m/load_and_authorize_resource', ref: 'a77cce9'
gem 'bcrypt', '~> 3.1.9'
gem 'mini_magick', '~> 4.0.2'
gem 'activerecord-session_store', '~> 0.1.1'
gem 'sass-rails', '~> 4.0.5'
gem 'bootstrap-sass', '~> 3.1.1.1'
gem 'will_paginate-bootstrap', '~> 1.0.1'
gem 'uglifier', '~> 2.7.0'
gem 'coffee-rails', '~> 4.0.1'
gem 'font-awesome-rails', github: 'bokmann/font-awesome-rails', ref: 'a67a67e'
gem 'truncate_html', '~> 0.9.3'
gem 'geocoder', '~> 1.2.7'
gem 'date_validator', '~> 0.7.1'
gem 'country_select', github: 'stefanpenner/country_select', ref: 'd3ba0b9'
gem 'responders', '~> 2.0.2'
gem 'dossier', '~> 2.12.2'
gem 'mustache', '~> 1.0.0'
gem 'github_api', '~> 0.12.2'
gem 'sucker_punch', '~> 1.3.2'

group :test do
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'shoulda-matchers', '~> 2.7.0', require: false
  gem 'webmock', '~> 1.20.4'
end

group :development do
  gem 'better_errors', '~> 2.1.1'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'watchr', '~> 0.7'
  gem 'terminal-notifier', '~> 1.6.2'
  gem 'capistrano', '~> 3.3.5'
  gem 'capistrano-newrelic', '~> 0.0.8'
  gem 'capistrano-bundler', '~> 1.1.4'
  gem 'capistrano-rails', '~> 1.1.2'
  gem 'quiet_assets', '~> 1.1.0'
end

group :development, :test do
  gem 'pry', '~> 0.10.1'
  gem 'pry-remote', '~> 0.1.8'
  gem 'pry-rails', '~> 0.3.2'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'spring', '~> 1.2.0'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'guard-rspec', '~> 4.5.0', require: false
  gem 'coveralls', '~> 0.7.3', require: false
  gem 'timecop'
end

group :production do
  gem 'newrelic_rpm', '~> 3.9.9.275'
end

require 'erb'
require 'yaml'

source 'https://rubygems.org'

gem 'rails', '4.2.3'

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
        gem 'mysql2', '~> 0.3.18'
      when 'postgresql'
        gem 'pg', '~> 0.18.2'
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

gem 'activerecord-session_store', '~> 0.1.1'
gem 'acts_as_list', '~> 0.7.2'
gem 'acts_as_taggable_on_steroids', github: 'seven1m/acts_as_taggable_on_steroids', ref: 'cffba03'
gem 'authority', '~> 3.0.0'
gem 'bcrypt', '~> 3.1.10'
gem 'bootstrap-sass', '~> 3.3.4.1'
gem 'builder', '~> 3.2.2'
gem 'coffee-rails', '~> 4.1.0'
gem 'country_select', github: 'stefanpenner/country_select', ref: 'fad7c1d'
gem 'date_validator', '~> 0.8.0'
gem 'draper', '~> 2.1.0'
gem 'feedjira', '~> 1.6.0'
gem 'font-awesome-rails', github: 'bokmann/font-awesome-rails', ref: '2137b6b'
gem 'geocoder', '~> 1.2.8'
gem 'github_api', '~> 0.12.3'
gem 'haml', '~> 4.0.6'
gem 'highline', '~> 1.7.2'
gem 'httparty', '~> 0.13.5'
gem 'jquery-rails', '~> 4.0.3'
gem 'load_and_authorize_resource', github: 'seven1m/load_and_authorize_resource', ref: 'a77cce9'
gem 'loofah', '~> 2.0.2'
gem 'mini_magick', '~> 4.2.7'
gem 'mustache', '~> 1.0.1'
gem 'nokogiri', '~> 1.6.6.2'
gem 'omniauth-facebook', '~> 2.0.1'
gem 'paperclip', '~> 4.2.1'
gem 'pdf-writer', github: 'Hermanverschooten/pdf-writer', require: 'pdf/writer', ref: 'f57c298'
gem 'pusher', '~> 0.14.5'
gem 'rails_autolink', '~> 1.1.6'
gem 'responders', '~> 2.1.0'
gem 'rubyzip', '~> 1.1.7'
gem 'sanitize', '~> 4.0.0'
gem 'sass-rails', '~> 5.0.3'
gem 'sucker_punch', '~> 1.5.0'
gem 'truncate_html', '~> 0.9.3'
gem 'uglifier', '~> 2.7.1'
gem 'whenever', '~> 0.9.4'
gem 'will_paginate', '~> 3.0.7'
gem 'will_paginate-bootstrap', '~> 1.0.1'
gem 'zip-zip', '~> 0.3'

# this needs to be down here due to load order weirdness
gem 'dossier', '~> 2.12.2'

group :test do
  gem 'factory_girl_rails', '~> 4.5.0'
  gem 'shoulda-matchers', '~> 2.8.0', require: false
  gem 'webmock', '~> 1.21.0'
end

group :development do
  gem 'better_errors', '~> 2.1.1'
  gem 'binding_of_caller', '~> 0.7.2'
  gem 'capistrano', '~> 3.4.0'
  gem 'capistrano-bundler', '~> 1.1.4'
  gem 'capistrano-newrelic', '~> 0.0.9'
  gem 'capistrano-rails', '~> 1.1.3'
  gem 'observr', '~> 1.0.5'
  gem 'quiet_assets', '~> 1.1.0'
  gem 'terminal-notifier', '~> 1.6.3'
end

group :development, :test do
  gem 'coveralls', '~> 0.8.1', require: false
  gem 'guard-rspec', '~> 4.5.1', require: false
  gem 'pry', '~> 0.10.1'
  gem 'pry-rails', '~> 0.3.4'
  gem 'pry-remote', '~> 0.1.8'
  gem 'rspec-rails', '~> 3.2.1'
  gem 'spring', '~> 1.3.6'
  gem 'spring-commands-rspec', '~> 1.0.4'
  gem 'timecop', '~> 0.7.4'
end

group :production do
  gem 'newrelic_rpm', '~> 3.12.0.288'
end

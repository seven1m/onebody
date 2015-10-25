source 'https://rubygems.org'

gem 'rails'

# select the appropriate gem below for your database:
gem 'mysql2'
#gem 'pg'

gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'acts_as_taggable_on_steroids', github: 'seven1m/acts_as_taggable_on_steroids'
gem 'authority'
gem 'bcrypt'
gem 'bootstrap-sass'
gem 'builder'
gem 'coffee-rails'
gem 'country_select'
gem 'date_validator'
gem 'draper'
gem 'feedjira'
gem 'flag_shih_tzu'
gem 'font-awesome-rails'
gem 'geocoder'
gem 'github_api'
gem 'haml'
gem 'highline'
gem 'httparty'
gem 'jquery-rails'
gem 'load_and_authorize_resource'
gem 'loofah'
gem 'mini_magick'
gem 'mustache'
gem 'nokogiri'
gem 'omniauth-facebook'
gem 'paperclip'
gem 'pdf-writer', github: 'Hermanverschooten/pdf-writer', require: 'pdf/writer', ref: 'f57c298'
gem 'pusher'
gem 'rails_autolink'
gem 'responders'
gem 'sanitize'
gem 'sass-rails'
gem 'strong_password'
gem 'sucker_punch', '~> 1.5.1' # 2.0.x doesn't appear to be compatible with ActiveJob
gem 'thin'
gem 'truncate_html'
gem 'tzinfo-data'
gem 'uglifier'
gem 'whenever'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'with_advisory_lock'
gem 'jsonapi-resources'

# this needs to be down here due to load order weirdness
gem 'dossier'

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers', '~> 2.8.0', require: false # I can't get 3.x to work (will try again later)
  gem 'test_after_commit'
  gem 'webmock'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-newrelic'
  gem 'capistrano-rails'
  gem 'observr'
  gem 'quiet_assets'
  gem 'terminal-notifier'
end

group :development, :test do
  gem 'coveralls', require: false
  gem 'guard-rspec', require: false
  gem 'pry'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'rspec-rails'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'timecop'
end

group :production do
  gem 'newrelic_rpm'
end

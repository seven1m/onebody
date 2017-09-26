# rubocop:disable Metrics/LineLength, Layout/LeadingCommentSpace

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '5.1.4'

# select the appropriate gem below for your database:
gem 'mysql2'
#gem 'pg'

gem 'activemodel-serializers-xml'
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
gem 'erubis'
gem 'feedjira'
gem 'flag_shih_tzu'
gem 'font-awesome-rails'
gem 'geocoder'
gem 'github_api'
gem 'haml', '~> 4.0.7' # 5.0.x has formatting issues caused by removal of the :ugly option https://git.io/v5i0G
gem 'highline'
gem 'html_truncator'
gem 'httparty'
gem 'jquery-rails'
gem 'load_and_authorize_resource'
gem 'loofah'
gem 'mini_magick'
gem 'mustache'
gem 'nokogiri'
gem 'omniauth-facebook'
gem 'paperclip'
gem 'prawn'
gem 'pusher'
gem 'rails_autolink'
gem 'react-rails'
gem 'responders'
gem 'sanitize'
gem 'sass-rails'
gem 'strong_password'
gem 'sucker_punch'
gem 'thin'
gem 'tzinfo-data'
gem 'uglifier'
gem 'webpacker'
gem 'whenever'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
gem 'with_advisory_lock'

# this needs to be down here due to load order weirdness
gem 'dossier'

group :test do
  gem 'factory_girl_rails'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers', github: 'thoughtbot/shoulda-matchers'
  gem 'webmock'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-newrelic'
  gem 'capistrano-rails'
  gem 'capistrano-yarn'
  gem 'observr'
  gem 'terminal-notifier'
end

group :development, :test do
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

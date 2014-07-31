source 'http://rubygems.org'

ruby File.read(File.expand_path('../.ruby-version', __FILE__)).strip.sub(/ruby\-/, '')

gem 'rails', '~> 4.1.4'
gem 'rails_autolink'
gem 'mysql2'
gem 'jquery-rails'
gem 'will_paginate', '3.0.7'
gem 'highline'
gem 'whenever'
gem 'nokogiri'
gem 'builder'
gem 'loofah'
gem 'feedjira'
gem 'rubyzip'
gem 'zip-zip'
gem 'sanitize'
gem 'haml'
gem 'draper'
gem 'paperclip'
gem 'acts_as_taggable_on_steroids', github: 'seven1m/acts_as_taggable_on_steroids'
gem 'pdf-writer', github: 'Hermanverschooten/pdf-writer', require: 'pdf/writer'
gem 'authority'
gem 'load_and_authorize_resource', github: 'seven1m/load_and_authorize_resource'
gem 'bcrypt'
gem 'mini_magick'
gem 'activerecord-session_store'
gem 'sass-rails', '~> 4.0.2'
gem 'bootstrap-sass', '~> 3.1.1'
gem 'will_paginate-bootstrap', '1.0.1'
gem 'uglifier'
gem 'coffee-rails', '~> 4.0.0'
gem 'font-awesome-rails', github: 'bokmann/font-awesome-rails'
gem 'truncate_html'
gem 'geocoder'
gem 'date_validator'

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers', require: false
end

group :development do
  gem 'zeus'
  gem 'watchr'
  gem 'terminal-notifier'
  gem 'capistrano'
  gem 'capistrano-newrelic'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
end

group :development, :test do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.0.0.beta'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec', require: false
  gem 'timecop'
end

group :production do
  gem 'newrelic_rpm'
end

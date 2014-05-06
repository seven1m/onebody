source 'http://rubygems.org'

gem 'rails', '3.2.17'
gem 'rails_autolink'
gem 'strong_parameters'
gem 'mysql2'
gem 'jquery-rails'
gem 'will_paginate'
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
gem 'sass'
gem 'paperclip'
gem 'acts_as_taggable_on_steroids', github: 'PavelNartov/acts_as_taggable_on_steroids', require: 'acts_as_taggable'
gem 'pdf-writer', github: 'metaskills/pdf-writer', require: 'pdf/writer'
gem 'authority'
gem 'load_and_authorize_resource'
gem 'bcrypt'
gem 'mini_magick'

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
end

group :development do
  gem 'zeus'
  gem 'watchr'
  gem 'terminal-notifier' if RUBY_PLATFORM =~ /darwin/
end

group :development, :test do
  gem 'pry'
  gem 'rspec-rails', '~> 3.0.0.beta'
end

group :production do
  gem 'exception_notification'
end

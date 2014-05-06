# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.order = 'random'
  config.include SessionHelper
  config.include MailHelper
  config.before do
    Site.current ||= Site.where(host: 'example.com').first_or_create! do |site|
      site.name = 'Default'
    end
  end
end

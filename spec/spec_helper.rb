# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include SessionHelper
  config.include MailHelper

  config.order = 'random'
  config.use_transactional_fixtures = true
  ActiveRecord::Migration.maintain_test_schema!

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  config.before(:all) do
    begin
      Site.current ||= Site.find(1)
    rescue ActiveRecord::RecordNotFound
      Site.connection.execute("DELETE FROM sites;")
      Site.connection.execute("ALTER TABLE sites AUTO_INCREMENT = 1;")
      Site.current = Site.create!(name: 'Default', host: 'example.com')
    end
    Setting.update_all
  end

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join('public/system/test'))
  end
end

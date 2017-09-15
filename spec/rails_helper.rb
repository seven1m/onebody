# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'sucker_punch/testing/inline'

Dir[Rails.root.join('spec/support/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include SessionHelper
  config.include MailHelper

  config.use_transactional_fixtures = true
  config.fixture_path = Rails.root.join('spec/fixtures')

  ActiveRecord::Migration.maintain_test_schema!

  config.before(:all) do
    begin
      Site.current = Site.find(1)
    rescue ActiveRecord::RecordNotFound
      Site.connection.execute('DELETE FROM sites;')
      if Site.connection.adapter_name == 'PostgreSQL'
        Site.connection.execute('ALTER SEQUENCE sites_id_seq RESTART WITH 1;')
        Site.connection.execute('UPDATE sites SET id = DEFAULT;')
      else
        Site.connection.execute('ALTER TABLE sites AUTO_INCREMENT = 1;')
      end
      Setting.update_all
      Site.current = Site.create!(name: 'Default', host: 'example.com')
    end
    Setting.update_all
  end

  config.before(:each) do
    Site.current = Site.find(1)
    ActionMailer::Base.deliveries.clear
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    allow(StreamItemGroupJob).to receive(:perform_later)
    Geocoder.configure(lookup: :test)
    Geocoder::Lookup::Test.set_default_stub([{
      'latitude'     => 40.7143528,
      'longitude'    => -74.0059731,
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US',
      'precision'    => 'RANGE_INTERPOLATED'
    }])
  end

  config.after(:each) do
    Timecop.return
  end

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join('public/system/test'))
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

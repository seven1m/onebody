ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/application', __FILE__)
require 'rails/test_help'
#require 'notifier'
require 'rake'
require File.expand_path('../../lib/rake_abandon', __FILE__)
OneBody::Application.load_tasks

# flatten settings hash and write to fixture file
Rake::Task['onebody:build_settings_fixture_file'].invoke

#Webrat.configure do |config|
  #config.mode = :selenium
  #config.application_framework = :rails
  #config.application_environment = :test
  #config.application_port = 4567
#end

require File.dirname(__FILE__) + '/forgeries'

class ActiveSupport::TestCase

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  def sign_in_as(person, password='secret')
    sign_in_and_assert_name(person.email, person.name, password)
  end

  def sign_in_and_assert_name(email, name, password='secret')
    post_sign_in_form(email, password)
    assert_response :redirect
    follow_redirect!
    assert_select 'li', I18n.t("session.sign_out")
  end

  def post_sign_in_form(email, password='secret')
    Setting.set_global('Features', 'SSL', true)
    post '/session', :email => email, :password => password
  end

  def view_profile(person)
    get "/people/#{person.id}"
    assert_response :success
    assert_template 'people/show'
    assert_select 'h2', Regexp.new(person.name)
  end

  def site!(site)
    host! site
    get '/'
  end

  def assert_deliveries(count)
    assert_equal count, ActionMailer::Base.deliveries.length
  end

  def assert_emails_delivered(email, people)
    people.each do |person|
      matches = ActionMailer::Base.deliveries.select do |delivered|
        delivered.subject == email.subject and \
        delivered.body.to_s.index(email.body.to_s) and \
        delivered.to == [person.email]
      end
      assert_equal 1, matches.length
    end
  end

  fixtures :all

  setup do
    # this is so fixture loading and forgeries won't bomb
    # (since they are often loaded before AppplicaitonController can call get_site)
    Site.current = Site.find(1)
  end
end

module WebratTestHelper
  def sign_in_as(person, password='secret')
    visit '/session/new'
    fill_in :email, :with => person.email
    fill_in :password, :with => password
    click_button I18n.t('session.sign_in')
    selenium.wait_for_page_to_load(5)
    assert_match %r{/stream$}, current_url
  end

  def assert_display(display, selector)
    assert_equal display, selenium.js_eval("window.$('#{selector}').css('display')")
  end

  def assert_has_focus(id)
    id.sub!(/^#/, '')
    assert_equal id, selenium.js_eval("window.$(':focus')[0].id")
  end
end

if ENV['SELENIUM_RUNNING']
  # set SELENIUM_RUNNING=true when running tests to
  # skip start and stop of selenium rc server
  module Webrat
    module Selenium
      class SeleniumRCServer
        def start
          # should already be running
        end
        def stop
          # leave it running
        end
      end
    end
  end
end

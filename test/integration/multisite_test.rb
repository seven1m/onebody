require "#{File.dirname(__FILE__)}/../test_helper"

class MultisiteTest < ActionController::IntegrationTest
  def setup
    Site.current = Site.create!(name: 'Site One', host: 'host1')
    @user1 = FactoryGirl.create(:person, email: 'site1user@example.com', first_name: 'Jim', last_name: 'Williams')
    Site.current = Site.create!(name: 'Site Two', host: 'host2')
    @user2 = FactoryGirl.create(:person, email: 'site2user@example.com', first_name: 'Tom', last_name: 'Jones')
    Setting.set_global('Features', 'Multisite', true)
  end

  def teardown
    Setting.set_global('Features', 'Multisite', false)
    site! 'www.example.com'
    Site.current = Site.find(1)
  end

  def test_login
    site! 'host1'
    post_sign_in_form @user2.email
    assert_response :success
    assert_select 'body', /email address cannot be found/
    site! 'host2'
    post_sign_in_form @user1.email
    assert_response :success
    assert_select 'body', /email address cannot be found/
  end

  def test_browse
    site! 'host1'
    sign_in_as @user1
    get '/search', browse: true
    assert_select 'body', /1 person found/
    assert_select 'body', /Jim Williams/
    assert_select 'body', html: /Tom Jones/, count: 0
    get "/people/#{@user2.id}"
    assert_response :missing
  end
end

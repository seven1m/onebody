require "#{File.dirname(__FILE__)}/../test_helper"

class MultisiteTest < ActionController::IntegrationTest
  def setup
    Setting.set_global('Features', 'Multisite', true)
  end
  
  def teardown
    Setting.set_global('Features', 'Multisite', false)
    site! 'www.example.com'
  end
  
  def test_login
    site! 'site1'
    post_sign_in_form 'tom@example.com'
    assert_response :success
    assert_select 'body', /email address cannot be found/
    site! 'site2'
    sign_in_as people(:tom)
    post_sign_in_form 'jim@example.com'
    assert_response :success
    assert_select 'body', /email address cannot be found/
  end
  
  def test_browse
    site! 'site1'
    sign_in_as people(:jim)
    get '/search', :browse => true
    assert_select 'body', /1 person found/
    assert_select 'body', /Jim Williams/
    assert_select 'body', :html => /Tom Jones/, :count => 0
    get '/people/view/9'
    assert_response :missing
  end
end

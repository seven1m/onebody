require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  fixtures :people

  def test_sign_in
    get '/'
    assert_redirected_to :controller => 'account', :action => 'sign_in'
    follow_redirect!
    post '/account/sign_in', :email => 'bad-email', :password => ''
    assert_response :success
    assert_select 'div#notice', /email address/
    post '/account/sign_in', :email => people(:peter).email, :password => 'wrong-password'
    assert_response :success
    assert_select 'div#notice', /password/
    post '/account/sign_in', :email => people(:peter).email, :password => 'secret'
    assert_redirected_to :controller => 'people', :action => 'index'
  end
end

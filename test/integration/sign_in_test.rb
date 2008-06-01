require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  fixtures :people

  def test_sign_in
    Setting.set(nil, 'Features', 'SSL', true)
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
    assert_redirected_to logged_in_path
  end
  
  def test_email_address_sharing_among_family_members
    Setting.set(nil, 'Features', 'SSL', true)
    # tim
    post '/account/sign_in', :email => people(:tim).email, :password => 'secret'
    assert_redirected_to logged_in_path
    follow_redirect!
    assert_template 'people/view'
    assert_select 'h1', Regexp.new(people(:tim).name)
    # jennie
    post '/account/sign_in', :email => people(:jennie).email, :password => 'password'
    assert_redirected_to logged_in_path
    follow_redirect!
    assert_template 'people/view'
    assert_select 'h1', Regexp.new(people(:jennie).name)
  end
end

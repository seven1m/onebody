require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  fixtures :people

  def test_sign_in
    Setting.set(nil, 'Features', 'SSL', true)
    get '/'
    assert_redirected_to new_session_path(:from => '/')
    follow_redirect!
    post '/session', :email => 'bad-email', :password => ''
    assert_response :success
    assert_select 'div#notice', /email address/
    post '/session', :email => people(:peter).email, :password => 'wrong-password'
    assert_response :success
    assert_select 'div#notice', /password/
    post '/session', :email => people(:peter).email, :password => 'secret'
    assert_redirected_to person_path(people(:peter))
  end
  
  def test_email_address_sharing_among_family_members
    Setting.set(nil, 'Features', 'SSL', true)
    # tim
    post '/session', :email => people(:tim).email, :password => 'secret'
    assert_redirected_to person_path(people(:tim))
    follow_redirect!
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(people(:tim).name)
    # jennie
    post '/session', :email => people(:jennie).email, :password => 'password'
    assert_redirected_to person_path(people(:jennie))
    follow_redirect!
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(people(:jennie).name)
  end
end

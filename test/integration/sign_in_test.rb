require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  fixtures :people

  should "allow sign in" do
    Setting.set(nil, 'Features', 'SSL', true)
    get '/people'
    assert_redirected_to new_session_path(from: '/people')
    follow_redirect!
    post '/session', email: 'bad-email', password: 'bla'
    assert_response :success
    assert_select 'div#notice', /email address/
    post '/session', email: people(:peter).email, password: 'wrong-password'
    assert_response :success
    assert_select 'div#notice', /password/
    post '/session', email: people(:peter).email, password: 'secret'
    assert_redirected_to stream_path
  end

  should "allow family members to share an email address" do
    Setting.set(nil, 'Features', 'SSL', true)
    # tim
    post '/session', email: people(:tim).email, password: 'secret'
    assert_redirected_to stream_path
    follow_redirect!
    assert_template 'streams/show'
    assert_select 'li', I18n.t("session.sign_out")
    # jennie
    post '/session', email: people(:jennie).email, password: 'password'
    assert_redirected_to stream_path
    follow_redirect!
    assert_template 'streams/show'
    assert_select 'li', I18n.t("session.sign_out")
  end

  should "not allow users to access most actions with feed code" do
    get "/people?code=#{people(:tim).feed_code}"
    assert_response :redirect
    get "/groups?code=#{people(:tim).feed_code}"
    assert_response :redirect
    get "/stream.xml?code=#{people(:tim).feed_code}"
    assert_response :success
    get "/groups/#{groups(:morgan).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=off"
    assert_redirected_to people_path
  end

end

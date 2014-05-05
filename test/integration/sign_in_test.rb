require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  setup do
    @user = FactoryGirl.create(:person)
    Setting.set(nil, 'Features', 'SSL', true)
  end

  context 'given sign in with wrong email address' do
    setup do
      post '/session', email: 'bad-email', password: 'bla'
    end

    should 'show error message' do
      assert_response :success
      assert_select 'div#notice', /email address/
    end
  end

  context 'given sign in with wrong password' do
    setup do
      post '/session', email: @user.email, password: 'wrong-password'
    end

    should 'show error message' do
      assert_response :success
      assert_select 'div#notice', /password/
    end
  end

  context 'given proper email and password' do
    setup do
      post '/session', email: @user.email, password: 'secret'
    end

    should 'redirect to stream' do
      assert_redirected_to stream_path
    end
  end

  context 'given two users in the same family with the same email address' do
    setup do
      @user2 = FactoryGirl.create(:person, email: @user.email, family: @user.family)
    end

    should 'allow both to sign in' do
      post '/session', email: @user.email, password: 'secret'
      assert_redirected_to stream_path
      post '/session', email: @user2.email, password: 'secret'
      assert_redirected_to stream_path
    end
  end

  context 'given a session using a "feed code"' do
    should 'allow access to stream xml' do
      get "/stream.xml?code=#{@user.feed_code}"
      assert_response :success
    end

    should 'allow access to disable group emails' do
      @group = FactoryGirl.create(:group)
      @membership = @group.memberships.create!(person: @user)
      get "/groups/#{@group.id}/memberships/#{@user.id}?code=#{@user.feed_code}&email=off"
      assert_redirected_to people_path
      assert_equal false, @membership.reload.get_email
    end

    should 'not allow user to access most other actions' do
      get "/people?code=#{@user.feed_code}"
      assert_response :redirect
      get "/groups?code=#{@user.feed_code}"
      assert_response :redirect
    end
  end
end

require_relative '../rails_helper'

describe 'SignIn', type: :request do
  before do
    @user = FactoryGirl.create(:person)
    Setting.set(nil, 'Features', 'SSL', true)
  end

  context 'given sign in with wrong email address' do
    before do
      post '/session',
           params: { email: 'bad-email', password: 'bla' }
    end

    it 'should show error message' do
      expect(response).to be_success
      assert_select 'div.callout', /email address/
    end
  end

  context 'given sign in with wrong password' do
    before do
      post '/session',
           params: { email: @user.email, password: 'wrong-password' }
    end

    it 'should show error message' do
      expect(response).to be_success
      assert_select 'div.callout', /password/
    end
  end

  context 'given proper email and password' do
    before do
      post '/session',
           params: { email: @user.email, password: 'secret' }
    end

    it 'should redirect to stream' do
      expect(response).to redirect_to(stream_path)
    end
  end

  context 'given two users in the same family with the same email address' do
    before do
      @user2 = FactoryGirl.create(:person, email: @user.email, family: @user.family)
    end

    it 'should allow both to sign in' do
      post '/session',
           params: { email: @user.email, password: 'secret' }
      expect(response).to redirect_to(stream_path)
      post '/session',
           params: { email: @user2.email, password: 'secret' }
      expect(response).to redirect_to(stream_path)
    end
  end

  context 'given a session using a "feed code"' do
    it 'should allow access to stream xml' do
      get "/stream.xml?code=#{@user.feed_code}"
      expect(response).to be_success
    end

    it 'should allow access to disable group emails' do
      @group = FactoryGirl.create(:group)
      @membership = @group.memberships.create!(person: @user)
      get "/groups/#{@group.id}/memberships/#{@user.id}?code=#{@user.feed_code}&email=off",
          headers: { referer: "/groups/#{@group.id}" }
      expect(response).to render_template(:email)
    end

    it 'should not allow user to access most other actions' do
      get "/people?code=#{@user.feed_code}"
      expect(response).to be_redirect
      get "/groups?code=#{@user.feed_code}"
      expect(response).to be_redirect
    end
  end
end

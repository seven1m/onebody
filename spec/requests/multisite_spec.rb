require 'rails_helper'

describe 'MultiSite', type: :request do
  before do
    Site.current = Site.create!(name: 'Site One', host: 'host1')
    @user1 = FactoryGirl.create(:person, email: 'site1user@example.com', first_name: 'Jim', last_name: 'Williams')
    Site.current = Site.create!(name: 'Site Two', host: 'host2')
    @user2 = FactoryGirl.create(:person, email: 'site2user@example.com', first_name: 'Tom', last_name: 'Jones')
    Setting.set_global('Features', 'Multisite', true)
  end

  after do
    Setting.set_global('Features', 'Multisite', false)
    site! 'www.example.com'
    Site.current = Site.find(1)
  end

  it 'logs in' do
    site! 'host1'
    post_sign_in_form @user2.email
    expect(response).to be_success
    assert_select 'body', /email address cannot be found/
    site! 'host2'
    post_sign_in_form @user1.email
    expect(response).to be_success
    assert_select 'body', /email address cannot be found/
  end

  it 'browses' do
    site! 'host1'
    sign_in_as @user1
    get '/search',
        params: { browse: true }
    assert_select 'body', /1 person found/
    assert_select 'body', /Jim Williams/
    assert_select 'body', html: /Tom Jones/, count: 0
    get "/people/#{@user2.id}"
    expect(response).to be_missing
  end
end

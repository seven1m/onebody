require_relative '../../../rails_helper'

describe 'Groups API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of groups' do
    FactoryGirl.create_list(:group, 10)

    get '/api/v2/groups', :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific group' do
    group = FactoryGirl.create(:group)

    get "/api/v2/groups/#{group.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(group.id)
    expect(json_attributes['name']).to eq(group.name)
  end

  it 'should retrieve the group members' do
    group = FactoryGirl.create(:group)
    members = FactoryGirl.create_list(:person, 10)
    members.each { |member| group.memberships.create(person: member) }

    get "/api/v2/groups/#{group.id}/people", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrive the group admins' do
    group = FactoryGirl.create(:group)
    members = FactoryGirl.create_list(:person, 10)
    admin = FactoryGirl.create(:person)
    members.each { |member| group.memberships.create(person: member) }
    group.memberships.create(person: admin, admin: true)

    get "/api/v2/groups/#{group.id}/admins", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(1)
    expect(json_data[0]['id'].to_i).to eq(admin.id)
  end

  it 'should retrieve the group creator' do
    creator = FactoryGirl.create(:person)
    group = FactoryGirl.create(:group, creator: creator)

    get "/api/v2/groups/#{group.id}/creator", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(creator.id)
  end

  it 'should retrieve the group leader' do
    leader = FactoryGirl.create(:person)
    group = FactoryGirl.create(:group, leader: leader)

    get "/api/v2/groups/#{group.id}/leader", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(leader.id)
  end
end
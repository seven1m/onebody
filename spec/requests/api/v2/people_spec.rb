require_relative '../../../rails_helper'

describe 'People API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of people' do
    FactoryGirl.create_list(:person, 10)

    get '/api/v2/people', :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific person' do
    person = FactoryGirl.create(:person)

    get "/api/v2/people/#{person.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_attributes['first-name']).to eq(person.first_name)
  end

  it 'should should retrieve the family' do
    person = FactoryGirl.create(:person)

    get "/api/v2/people/#{person.id}/family", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.family.id)
    expect(json_attributes['name']).to eq(person.family.name)
    expect(json_data['type']).to eq('families')
  end

  it 'should retrieve the groups a person belongs to' do
    person = FactoryGirl.create(:person)
    groups = FactoryGirl.create_list(:group, 3)
    groups.each { |group| group.memberships.create(person: person) }

    get "/api/v2/people/#{person.id}/groups", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(3)
    expect(json_data[0]['type']).to eq('groups')
  end

  context 'with friends' do
    it 'should retrieve a list of friends' do
      person = FactoryGirl.create(:person)
      friends = FactoryGirl.create_list(:person, 3)
      friends.each do |friend|
        person.friendships.create(friend: friend)
      end

      get "/api/v2/people/#{person.id}/friends", :access_token => token.token

      expect(response).to be_success
      expect(json_data.length).to eq(3)
      expect(json_data[0]['type']).to eq('people')
    end
  end

  context 'without friends' do
    it 'should return an empty list of friends' do
      person = FactoryGirl.create(:person)

      get "/api/v2/people/#{person.id}/friends", :access_token => token.token

      expect(response).to be_success
      expect(json_data.length).to be(0)
    end
  end

end
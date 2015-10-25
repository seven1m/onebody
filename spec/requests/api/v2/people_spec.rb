require_relative '../../../rails_helper'

describe 'People API', type: :request do

  it 'should return a list of people' do
    FactoryGirl.create_list(:person, 10)

    get '/api/v2/people'

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific person' do
    person = FactoryGirl.create(:person)

    get "/api/v2/people/#{person.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_attributes['first-name']).to eq(person.first_name)
  end

  it 'should should retrieve the family' do
    person = FactoryGirl.create(:person)

    get "/api/v2/people/#{person.id}/family"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.family.id)
    expect(json_attributes['name']).to eq(person.family.name)
    expect(json_data['type']).to eq('families')
  end

  it 'should retrieve the groups a person belongs to' do
    person = FactoryGirl.create(:person)
    groups = FactoryGirl.create_list(:group, 3)
    groups.each { |group| group.memberships.create(person: person) }

    get "/api/v2/people/#{person.id}/groups"

    expect(response).to be_success
    expect(json_data.length).to eq(3)
    expect(json_data[0]['type']).to eq('groups')
  end


end
require_relative '../../../rails_helper'

describe 'Comments API', type: :request do

  it 'should return a list of comments' do
    FactoryGirl.create_list(:comment, 10)

    get "/api/v2/comments"

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific comment' do
    comment = FactoryGirl.create(:comment)

    get "/api/v2/comments/#{comment.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(comment.id)
  end

  it 'should retrieve the person of a comment' do
    person = FactoryGirl.create(:person)
    comment = FactoryGirl.create(:comment, person: person)

    get "/api/v2/comments/#{comment.id}/person"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_data['type']).to eq('people')
  end

end